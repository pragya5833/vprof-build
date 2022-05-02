const express = require("express");

const app = new express();
const path = require("path");
const { config, engine } = require("express-edge");


app.use(express.static("public"));
app.use(engine);
app.set("views", __dirname + "/views");

app.listen(4005, () => {
  console.log("App listening on port 4005");
});
app.get("/", (req, res) => {
    res.render("index");
});
app.get("/about", (req, res) => {
  res.render("about");
});
app.get("/contact", (req, res) => {
  res.render("contact");
});
app.get("/post", (req, res) => {
  res.render("post");
});
app.get("/Interview-preparation-for-engineering-manager-role", (req, res) => {
  const postData = {
    title: "Interview preparation for engineering manager role",
    description: "complete guild for interview preparation for entry level engineering manager role",
    posts: [
      {
        title: "Focus Areas for engineering manager interviews",
        description: "Focus Areas for engineering manager interviews",
        url: "/",
      },
      {
        title: "System design interview for engineering managers",
        description: "System design interview for engineering managers",
        url: "/",
      },
      {
        title: "Leadership interview for engineering managers",
        description: "Leadership interview for engineering managers",
        url: "/",
      },
      {
        title: "Project Management interview for engineering managers",
        description: "Project Management for engineering managers",
        url: "/",
      },
    ],
  };
  res.render("postDynamic", {postData});
});
app.get("/First-90-days-plan-for-engineering-manager", (req, res) => {
  res.render("post");
});
app.get("/Moving-from-tech-lead-to-engineering-manager", (req, res) => {
  res.render("post");
});
