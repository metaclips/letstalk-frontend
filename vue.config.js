
module.exports = {
  "transpileDependencies": [
    "vuetify"
  ],
  "devServer": {
    "https": {},
    "proxy": {
      "/login": "http://127.0.0.1:8080/v1/login"
    }
  }
}