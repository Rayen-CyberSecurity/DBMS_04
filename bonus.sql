-- Bonus 1: Hourly Rate History
-- This extension stores mechanic hourly rates historically.
-- The mechanic table stores only mechanic identity data.
-- The mechanic_rate table stores rates with validity periods.
-- The work_item table references the exact historical rate used.

DROP TABLE IF EXISTS order_part;
DROP TABLE IF EXISTS part;
DROP TABLE IF EXISTS work_item;
DROP TABLE IF EXISTS mechanic_rate;
DROP TABLE IF EXISTS mechanic;
DROP TABLE IF EXISTS "order";
DROP TABLE IF EXISTS vehicle;
DROP TABLE IF EXISTS customer;

PRAGMA foreign_keys = ON;

CREATE TABLE customer (
    cust_no   INTEGER PRIMARY KEY,
    cust_name TEXT    NOT NULL,
    cust_city TEXT    NOT NULL
);

CREATE TABLE vehicle (
    plate    TEXT    PRIMARY KEY,
    cust_no  INTEGER NOT NULL,
    make     TEXT    NOT NULL,
    model    TEXT    NOT NULL,
    year     INTEGER NOT NULL,

    FOREIGN KEY (cust_no) REFERENCES customer(cust_no)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE "order" (
    order_no INTEGER PRIMARY KEY,
    plate    TEXT    NOT NULL,
    cust_no  INTEGER NOT NULL,
    date     DATE    NOT NULL,

    FOREIGN KEY (plate) REFERENCES vehicle(plate)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    FOREIGN KEY (cust_no) REFERENCES customer(cust_no)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE mechanic (
    mech_id   INTEGER PRIMARY KEY,
    mech_name TEXT NOT NULL
);

CREATE TABLE mechanic_rate (
    mech_id     INTEGER NOT NULL,
    valid_from  DATE    NOT NULL,
    valid_to    DATE,
    hourly_rate REAL    NOT NULL CHECK (hourly_rate > 0),

    PRIMARY KEY (mech_id, valid_from),

    FOREIGN KEY (mech_id) REFERENCES mechanic(mech_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CHECK (valid_to IS NULL OR valid_to > valid_from)
);

CREATE TABLE work_item (
    order_no        INTEGER NOT NULL,
    item_no         INTEGER NOT NULL,
    mech_id         INTEGER NOT NULL,
    rate_valid_from DATE    NOT NULL,
    description     TEXT    NOT NULL,
    hours           REAL    NOT NULL CHECK (hours > 0),

    PRIMARY KEY (order_no, item_no),

    FOREIGN KEY (order_no) REFERENCES "order"(order_no)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (mech_id, rate_valid_from)
        REFERENCES mechanic_rate(mech_id, valid_from)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- Bonus 2: Spare Parts
-- A part can be used in many orders.
-- An order can contain many parts.
-- Therefore, order_part is a join table.

CREATE TABLE part (
    part_id    INTEGER PRIMARY KEY,
    part_name  TEXT NOT NULL,
    unit_price REAL NOT NULL CHECK (unit_price > 0)
);

CREATE TABLE order_part (
    order_no INTEGER NOT NULL,
    part_id  INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),

    PRIMARY KEY (order_no, part_id),

    FOREIGN KEY (order_no) REFERENCES "order"(order_no)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (part_id) REFERENCES part(part_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- Bonus 3: Total Invoice per Order
-- Labour total only:
-- This query computes SUM(hours * historical hourly_rate) for each order.

SELECT
    o.order_no,
    ROUND(SUM(wi.hours * mr.hourly_rate), 2) AS labour_total
FROM "order" o
JOIN work_item wi
    ON o.order_no = wi.order_no
JOIN mechanic_rate mr
    ON wi.mech_id = mr.mech_id
   AND wi.rate_valid_from = mr.valid_from
GROUP BY o.order_no
ORDER BY o.order_no;
