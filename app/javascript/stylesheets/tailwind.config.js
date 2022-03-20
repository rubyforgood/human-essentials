module.exports = {
  purge: [
    "app/views/**/*.html.erb"
  ],
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {
      animation: {
        'pulse-once': 'pulse 1s ease-in-out'
      }
    },
  },
  variants: {
    extend: {
      borderWidth: ['last'],
    },
  },
  plugins: [],
}
