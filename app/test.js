const express = require("express");

const app = new express();


app.listen(4005, () => {
  console.log("App listening on port 4005");
});
app.get("/", (req, res) => {
  res.send({"data" : "hello world"});
});

