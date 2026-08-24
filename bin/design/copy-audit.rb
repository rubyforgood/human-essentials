#!/usr/bin/env ruby
# frozen_string_literal: true

# Copy audit: inclusive language, and the WCAG success criteria that are about *words*.
#
# The other audits look at markup and geometry. This one looks at what the words say, which axe
# cannot check: "Click here" is a perfectly accessible link as far as a machine is concerned, and
# useless to anyone reading a list of links out of context.
#
#   ruby bin/design/copy-audit.rb            report
#   ruby bin/design/copy-audit.rb --verbose  every finding with its file and line
#
# Three things this had to get right, each of which it got wrong first:
#
#   * It reads *copy*, not source. A grep cannot tell a sentence from an identifier -- the first
#     draft's `he/she` pattern matched `render "organizations/header"`, because
#     "organization[s/he]ader" contains it.
#   * It knows a link from a heading. WCAG 2.4.4 is about link labels and nothing else; applied
#     to all copy the vague-text check reported all sixteen cards titled "Details", which are
#     headings and perfectly fine.
#   * Its line numbers are source lines. The first version numbered findings by their position in
#     the list of extracted strings and called that a line number.
#
# Exit status is 1 when there are findings, so CI can hold the line once it is clean.

require "yaml"

ROOT = File.expand_path("../..", __dir__)
Dir.chdir(ROOT)

VERBOSE = ARGV.include?("--verbose")

# Mailers are exempt from the sensory and link-text checks but not the others: an email is not a
# web page, "the link below" is literally true there, and most of the templates are Devise's.
MAILER = %r{app/views/\w*mailer\w*/|app/views/users/mailer/|_mailer\.}

COPY_KEYS = %w[
  label title subtitle placeholder hint confirm caption legend prompt heading
  aria-label empty_title empty_body
].freeze

NBSP = "\u00A0"

Finding = Struct.new(:file, :line, :text, :kind)

# Blank a match out while keeping its newlines, so every line of the stripped text still lines up
# with the line it came from.
def blanked(match)
  n = match.count("\n")
  n.zero? ? " " : "\n" * n
end

def erb_text_nodes(src)
  out = src.dup
  out = out.gsub(/<%#.*?%>/m) { |m| blanked(m) }
  out = out.gsub(/<%.*?%>/m) { |m| blanked(m) }
  out = out.gsub(%r{<script.*?</script>}mi) { |m| blanked(m) }
  out = out.gsub(%r{<style.*?</style>}mi) { |m| blanked(m) }
  out = out.gsub(/<[^>]*>/m) { |m| blanked(m) }
  out = out.gsub("&nbsp;", " ").gsub("&mdash;", "-")
  out.lines.each_with_index.filter_map do |line, i|
    text = line.tr(NBSP, " ").strip
    text.empty? ? nil : [i + 1, text]
  end
end

# The text inside an <a>, which is a link label whatever else surrounds it.
def anchor_labels(src)
  labels = []
  src.scan(%r{<a\b[^>]*>(.*?)</a>}mi) do |inner,|
    text = inner.gsub(/<%.*?%>/m, " ").gsub(/<[^>]*>/m, " ")
      .gsub("&nbsp;", " ").tr(NBSP, " ").strip
    labels << text unless text.empty?
  end
  labels
end

# Returns [kind, text]. The kind is what separates "a vague heading", which is a style question,
# from "a vague link", which is WCAG 2.4.4.
def copy_literals(src)
  found = []
  quoted = '(["\'])((?:\\\\.|(?!\1).)*)\1'
  COPY_KEYS.each do |key|
    src.scan(/#{Regexp.escape(key)}:\s*#{quoted}/) { |_q, t| found << [:copy, t] }
  end
  src.scan(/["']aria-label["']\s*[:=>]+\s*#{quoted}/) { |_q, t| found << [:copy, t] }
  # A short label is fine when the link carries an `aria-label` that extends it -- that is the
  # WCAG 2.5.3 way of keeping a compact visible label while giving the accessible name the
  # context 2.4.4 asks for. Look at the rest of the call, not just the first argument, or the
  # audit reports a link that has already been fixed properly.
  src.to_enum(:scan, /(?:link_to|essentials_link_button)\s*\(?\s*#{quoted}/).each do
    text = Regexp.last_match(2)
    tail = src[Regexp.last_match.end(0), 400].to_s[/\A.*?(?:%>|\n\s*\n|\z)/m].to_s
    found << [tail.match?(/aria:\s*\{\s*label:|["']aria-label["']/) ? :named_link : :link, text]
  end
  buttons = "button_to|essentials_action_button|add_element_button|remove_element_button"
  src.scan(/(?:#{buttons})\s*\(?\s*#{quoted}/) { |_q, t| found << [:copy, t] }
  found.reject { |_k, t| t.strip.empty? }
end

def locale_strings(path)
  out = []
  walk = lambda do |node|
    case node
    when Hash then node.each_value { |v| walk.call(v) }
    when Array then node.each { |v| walk.call(v) }
    when String then out << node
    end
  end
  walk.call(YAML.safe_load_file(path, aliases: true))
  out
rescue
  []
end

def js_strings(src)
  found = []
  src.scan(/(?:confirm|alert)\s*\(\s*(["'`])((?:\\.|(?!\1).)*)\1/) { |_q, t| found << t }
  src.scan(/textContent\s*=\s*(["'`])((?:\\.|(?!\1).)*)\1/) { |_q, t| found << t }
  found
end

def corpus
  entries = []
  Dir.glob("app/views/**/*.erb").sort.each do |f|
    src = File.read(f)
    erb_text_nodes(src).each { |line, t| entries << [f, line, t, :copy] }
    anchor_labels(src).each { |t| entries << [f, nil, t, :link] }
    copy_literals(src).each { |kind, t| entries << [f, nil, t, kind] }
  end
  Dir.glob("app/{helpers,models,services,controllers}/**/*.rb").sort.each do |f|
    copy_literals(File.read(f)).each { |kind, t| entries << [f, nil, t, kind] }
  end
  Dir.glob("app/javascript/**/*.js").sort.each do |f|
    js_strings(File.read(f)).each { |t| entries << [f, nil, t, :copy] }
  end
  Dir.glob("config/locales/**/*.yml").sort.each do |f|
    locale_strings(f).each { |t| entries << [f, nil, t, :copy] }
  end
  entries
end

# WCAG 2.4.4 Link Purpose. A link's text has to say where it goes when read on its own, which is
# how a screen reader's link list presents it.
#
# One line, not /x. In extended mode Ruby strips literal spaces, so the first draft of this was
# looking for "clickhere" -- the probe table caught it before the audit could report a zero.
VAGUE_LINK = /\A[\s"'(]*(?:click here|here|this link|read more|learn more|more info(?:rmation)?|see more|more|details|click|link|this|go here|continue)[\s"'.,!)]*\z/i

# WCAG 1.3.3 Sensory Characteristics: instructions must not depend on shape, size or position.
# `\s+` everywhere rather than a literal space, for the reason above.
SENSORY = /\b(?:link|button|field|form|table|box|section|menu)\s+(?:below|above)\b|
           \b(?:see|shown|listed|click)\s+(?:below|above)\b|
           \bto\s+the\s+(?:left|right)\b|
           \bthe\s+(?:green|red|blue|round|square)\s+(?:button|link|box)\b/xi

# Only the forms that are actually about a person, as whole words, on extracted copy.
GENDERED = %r{\b(?:he/she|s/he|his/her|him/her|he\s+or\s+she|his\s+or\s+her)\b|
              \b(?:chairman|chairwoman|manpower|man-hours|mankind|manned|salesman|salesmen)\b|
              \bguys\b}xi

# Metaphorical uses of disability, all of which have plainer replacements that say more.
ABLEIST = /\b(?:crazy|insane|insanely|lame|dumb|idiotic|moronic|psycho|schizophrenic|spaz)\b|
           \bsanity[\s-]check\b|\b(?:blind|deaf|tone-deaf)\s+to\b|\bcripple[sd]?\b|
           \bfalls?\s+on\s+deaf\s+ears\b|\bdummy\b/xi

# GOV.UK, Mailchimp and Shopify all say the same: drop it. In an instruction the reader has no
# choice about, it is not really a courtesy.
POLITENESS = /\bplease\b/i

# Screen readers may spell an all-capital word rather than read it. Domain acronyms are fine, and
# this list is the audit's memory of which ones are real -- FPL is Federal Poverty Level, NDBN the
# National Diaper Bank Network, PDX the Portland bank.
ACRONYMS = %w[
  CSV PDF URL URLS ID IDS FAQ FAQS US USA UK ZIP EIN API UPC GTIN HTML CSS JS YTD NDBN
  OK NO YES ASAP PO SKU QR AM PM UTC GMT EST PST CST MST TIN LLC INC NGO IRS DOB SSN
  FPL JPEG JPG PNG GIF SVG PDX RFP EIN NEW EDIT ADD
].to_set

def shouting(text)
  text.scan(/\b[A-Z]{3,}\b/).reject { |w| ACRONYMS.include?(w) }
end

CHECKS = {
  "link text (WCAG 2.4.4)" => ->(t, f, k) { k == :link && !f.match?(MAILER) && t.match?(VAGUE_LINK) },
  "sensory instruction (WCAG 1.3.3)" => ->(t, f, _k) { !f.match?(MAILER) && t.match?(SENSORY) },
  "gendered wording" => ->(t, _f, _k) { t.match?(GENDERED) },
  "ableist wording" => ->(t, _f, _k) { t.match?(ABLEIST) },
  "politeness filler" => ->(t, _f, _k) { t.match?(POLITENESS) },
  "shouting" => ->(t, _f, _k) { !shouting(t).empty? }
}.freeze

# Three of this repository's audits were once found checking a proxy rather than the property
# they claimed to check, and each reported a clean zero while doing it. Every case below is one
# these checks got wrong at some point, or one a careless pattern would get wrong.
LINK = "link text (WCAG 2.4.4)"
SENS = "sensory instruction (WCAG 1.3.3)"
V = "app/views/x.erb"

PROBES = [
  ["click here", V, LINK, true, :link],
  ["Here", V, LINK, true, :link],
  ["Learn more", V, LINK, true, :link],
  ["this link", V, LINK, true, :link],
  ["Read more", V, LINK, true, :link],
  ["More info", V, LINK, true, :link],
  ["Add another item", V, LINK, false, :link],
  ["Here is the list of partners", V, LINK, false, :link],
  ["More info", "app/views/donation_mailer/x.erb", LINK, false, :link],
  # A card titled "Details" is a heading, not a link. Sixteen of them were reported as WCAG
  # failures until the corpus started carrying a kind.
  ["Details", V, LINK, false, :copy],
  # A vague visible label that carries an aria-label extending it is named, not nameless.
  ["More info", V, LINK, false, :named_link],

  ["Click the link below to continue", V, SENS, true, :copy],
  ["the button above", V, SENS, true, :copy],
  ["The panel to the right", V, SENS, true, :copy],
  ["Press the green button", V, SENS, true, :copy],
  ["See below for details", V, SENS, true, :copy],
  ["Below is a summary", V, SENS, false, :copy],
  ["Right to request", V, SENS, false, :copy],

  ["Ask him/her to confirm", V, "gendered wording", true, :copy],
  ["s/he must sign", V, "gendered wording", true, :copy],
  ["he or she may collect it", V, "gendered wording", true, :copy],
  ["Ask the chairman", V, "gendered wording", true, :copy],
  ['render "organizations/header"', V, "gendered wording", false, :copy],
  ["The other bank", V, "gendered wording", false, :copy],
  ["Manufacturer", V, "gendered wording", false, :copy],

  ["That would be crazy", V, "ableist wording", true, :copy],
  ["Run a sanity check", V, "ableist wording", true, :copy],
  ["blind to the problem", V, "ableist wording", true, :copy],
  ["a dummy record", V, "ableist wording", true, :copy],
  ["Blind Item", V, "ableist wording", false, :copy],
  ["Deafness services", V, "ableist wording", false, :copy],

  ["Please try again", V, "politeness filler", true, :copy],
  ["Pleasant Valley", V, "politeness filler", false, :copy],

  ["SAVE CHANGES", V, "shouting", true, :copy],
  ["Export to CSV", V, "shouting", false, :copy],
  ["At FPL or below", V, "shouting", false, :copy],
  ["JPEG or PNG", V, "shouting", false, :copy],
  ["NDBN member", V, "shouting", false, :copy]
].freeze

PROBES.each do |text, file, check, expected, kind|
  actual = CHECKS.fetch(check).call(text, file, kind)
  next if actual == expected

  abort "copy-audit: the #{check.inspect} check is wrong.\n" \
        "  #{text.inspect} (#{kind}) in #{file} => #{actual}, expected #{expected}."
end

findings = Hash.new { |h, k| h[k] = [] }
seen = Set.new

corpus.each do |file, line, text, kind|
  next if text.length > 400

  CHECKS.each do |name, test|
    next unless test.call(text, file, kind)
    next unless seen.add?([name, file, text])

    findings[name] << Finding.new(file, line, text, kind)
  end
end

total = findings.values.sum(&:size)

CHECKS.each_key do |name|
  hits = findings[name]
  puts format("%-34s %d", name, hits.size)
  next if hits.empty?

  shown = VERBOSE ? hits : hits.first(6)
  shown.each do |f|
    where = f.line ? "#{f.file}:#{f.line}" : f.file
    puts format("    %-52s %s", where.sub("app/views/", ""), f.text.strip[0, 74])
  end
  puts "    ... #{hits.size - shown.size} more (--verbose)" if hits.size > shown.size
end

puts
puts "#{total} finding(s) across #{findings.keys.count { |k| !findings[k].empty? }} check(s)"
exit(total.zero? ? 0 : 1)
