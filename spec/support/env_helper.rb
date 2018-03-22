def stub_env(key, value)
  allow(ENV).to receive(:[]).with(key) { value }
end
