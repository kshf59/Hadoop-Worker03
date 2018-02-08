DROP TABLE tagmap;

CREATE TABLE tagmap (
  app_id INTEGER NOT NULL,
  tag_id INTEGER NOT NULL,
  FOREIGN KEY(app_id) REFERENCES apps(id),
  FOREIGN KEY(tag_id) REFERENCES tags(id),
  PRIMARY KEY (app_id, tag_id)
);
