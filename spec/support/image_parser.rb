def extract_image(method, path)
  File.basename(page.find(method, path).native[:src]).split("?").first
end
