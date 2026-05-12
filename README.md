# DBMS_04 – Normalization in Practice: From Plain Text to DDL

**Module:** Databases · THGA Bochum  
**Lecturer:** Stephan Bökelmann · <sboekelmann@ep1.rub.de>  
**Repository:** <https://github.com/MaxClerkwell/DBMS_04>  
**Prerequisites:** DBMS_01, DBMS_02, DBMS_03, Lecture 04 (Normalization)  
**Duration:** 90 minutes

---

## Learning Objectives

After completing this exercise you will be able to:

- Translate a natural-language problem description into a **flat starting table**
- Systematically identify and write down **functional dependencies**
- Decompose the table step by step into **2NF** and **3NF**, verifying losslessness at each step
- Represent the normalized schema as a **PlantUML diagram**
- Implement the schema as **DDL** in SQLite and populate it with sample data
- Formulate three practical **SQL queries** that directly reflect relational algebra

**After completing this exercise you should be able to answer the following questions independently:**

- How do I recognize a partial or transitive dependency in a real table?
- Why is a decomposition only correct if it is lossless?
- When is 3NF sufficient — and when do I need BCNF?

---

## Check Prerequisites

```bash
sqlite3 --version
plantuml -version
git --version
```

> You should see three version strings — SQLite 3.x, PlantUML 1.x, and Git 2.x.
> If a tool is missing, install it:
>
> ```bash
> sudo apt-get install -y sqlite3 plantuml   # Debian / Ubuntu
> brew install sqlite3 plantuml              # macOS
> ```

> **Screenshot 1:** Take a screenshot of your terminal showing all three
> successful version checks and insert it here.
>
> <img width="788" height="424" alt="Pre" src="https://github.com/user-attachments/assets/e8d403b5-5399-4579-a80a-44ecfe74e8d7" />


---

## 0 – Fork and Clone the Repository

**Step 1 – Fork on GitHub:**  
Navigate to <https://github.com/MaxClerkwell/DBMS_04> and click **Fork**.
Keep the default settings and confirm.

**Step 2 – Clone your fork:**

```bash
git clone git@github.com:<your-username>/DBMS_04.git
cd DBMS_04
ls
```

> You should see only the `README.md`. You will create all further files
> yourself during this exercise.

---

## 1 – The Starting Point: A Workshop and Its Spreadsheet

A small car repair workshop has been managing its repair orders in a single
Excel spreadsheet for years. Each row describes one **work item** within an
order — a single task assigned to a mechanic. The table looks like this
(simplified):

| OrderNo | Date       | CustNo | CustName        | CustCity | Plate       | Make | Model | Year | MechId | MechName   | HourlyRate | ItemNo | Description         | Hours |
|---------|------------|--------|-----------------|----------|-------------|------|-------|------|--------|------------|------------|--------|---------------------|-------|
| 1001    | 2026-03-10 | K01    | Berger, Franz   | Bochum   | BO-AB 123   | VW   | Golf  | 2018 | M03    | Huber, Tom | 65.00      | 1      | Oil change          | 0.5   |
| 1001    | 2026-03-10 | K01    | Berger, Franz   | Bochum   | BO-AB 123   | VW   | Golf  | 2018 | M03    | Huber, Tom | 65.00      | 2      | Replace air filter  | 0.3   |
| 1002    | 2026-03-11 | K02    | Novak, Jana     | Herne    | HER-XY 44   | Ford | Focus | 2020 | M01    | Schulz, P. | 60.00      | 1      | Front brake pads    | 1.5   |
| 1003    | 2026-03-12 | K01    | Berger, Franz   | Bochum   | BO-CD 999   | BMW  | 320i  | 2019 | M03    | Huber, Tom | 65.00      | 1      | Service inspection  | 2.0   |
| 1003    | 2026-03-12 | K01    | Berger, Franz   | Bochum   | BO-CD 999   | BMW  | 320i  | 2019 | M01    | Schulz, P. | 60.00      | 2      | Tyre change         | 0.8   |

The primary key of this flat table is `(OrderNo, ItemNo)` — every combination
of order number and item number appears exactly once.

### Task 1a – Identify Anomalies

Read the table carefully and describe one concrete example of each:

1. **Update anomaly:** Which rows would need to be changed simultaneously if
   mechanic Huber raises his hourly rate to 70.00?
2. **Insert anomaly:** Can a new mechanic be added before they work on their
   first order? What is missing?
3. **Delete anomaly:** What information is permanently lost if order 1002 is
   deleted entirely?

> *Your answers:*
> Update anomaly:
>If mechanic Huber, Tom raises his hourly rate from 65.00 to 70.00, all rows where MechId = M03 must be updated. In the given table, this affects:
•	Order 1001, Item 1
•	Order 1001, Item 2
•	Order 1003, Item 1
If one row is forgotten, the database will contain inconsistent hourly rates for the same mechanic.


>Insert anomaly:
A new mechanic cannot be added before they work on their first order, because the flat table requires an OrderNo and ItemNo. Without an order item, there is no place to store only the mechanic data such as MechId, MechName, and HourlyRate.


>Delete anomaly:
If order 1002 is deleted entirely, we lose not only the repair item, but also the information about:
•	Customer K02, Novak, Jana
•	Her city, Herne
•	Vehicle HER-XY 44, Ford Focus 2020
•	Mechanic M01, Schulz, P., if this was the only row where he appeared


### Task 1b – Write Down Functional Dependencies

List all non-trivial functional dependencies you can identify in the flat table.
Use the notation $X \rightarrow Y$.

Hints:
- Which attributes uniquely determine the customer?
- Which attributes follow from the licence plate alone?
- What does a single mechanic ID determine?
- What only follows from the combination `(OrderNo, ItemNo)`?

> *Your FD list:*
> A good FD list is:
CustNo → CustName, CustCity

Plate → Make, Model, Year, CustNo

MechId → MechName, HourlyRate

OrderNo → Date, CustNo, Plate

(OrderNo, ItemNo) → Description, Hours, MechId
You can also say the full primary key determines the whole row:
(OrderNo, ItemNo) → Date, CustNo, CustName, CustCity, Plate, Make, Model, Year,
                    MechId, MechName, HourlyRate, Description, Hours
But for normalization, the smaller dependencies above are more useful.


### Questions for Task 1

**Question 1.1:** Is `CustNo → CustCity` a *full* or *partial* dependency with
respect to the primary key `(OrderNo, ItemNo)`? Justify your answer using the
definition from Lecture 04.

> *Your answer:*
> CustNo → CustCity is neither a full nor a partial dependency with respect to the primary key (OrderNo, ItemNo).

>A full or partial dependency must be considered in relation to the key. According to the Lecture 04 definition, a partial dependency exists when a non-key attribute depends on a proper subset of a candidate key.   >Here, the key is (OrderNo, ItemNo), but CustNo is not part of this key. Therefore, CustNo → CustCity is not a dependency from the whole key or from part of the key.

>However, it is still important because it contributes to a transitive dependency. Since an order determines the customer, and the customer determines the city, the city is indirectly determined through CustNo.

**Question 1.2:** Identify a transitive dependency in the flat table and explain
why it violates 3NF.

> *Your answer:*
> A transitive dependency in the flat table is:
> (OrderNo, ItemNo) → CustNo
>CustNo → CustName, CustCity
> Therefore: (OrderNo, ItemNo) → CustName, CustCity
> This is transitive because the primary key determines CustNo, and then CustNo determines CustName and CustCity.

>This violates 3NF because CustNo is not a superkey of the flat table, but it determines non-key attributes such as CustName and CustCity. In 3NF, non-key attributes should not depend on another non-key attribute. Lecture 04 explains that a transitive dependency occurs when X→Y and Y→Z, so Z depends on X through an intermediate attribute Y.

**Question 1.3:** Compute the attribute closure $\{\mathrm{OrderNo}\}^+$ using
your FD list. Is `OrderNo` alone a superkey of the flat table?

> *Your answer:*
> Question 1.3

>Using the FD list:

>OrderNo → Date, CustNo, Plate
>CustNo → CustName, CustCity
>Plate → Make, Model, Year, CustNo

>Start with:

>{OrderNo}+ = {OrderNo}

>Apply:

>OrderNo → Date, CustNo, Plate

>So now:

>{OrderNo}+ = {OrderNo, Date, CustNo, Plate}

>Then apply:

>CustNo → CustName, CustCity

>So now:

>{OrderNo}+ = {OrderNo, Date, CustNo, Plate, CustName, CustCity}

>Then apply:

>Plate → Make, Model, Year, CustNo

>So finally:

>{OrderNo}+ = {OrderNo, Date, CustNo, Plate, CustName, CustCity, Make, Model, Year}

>But this closure does not include:

>ItemNo, Description, Hours, MechId, MechName, HourlyRate

>So OrderNo alone is not a superkey of the flat table.

---

## 2 – Normalization

### Task 2a – Decompose into 2NF

All attributes that depend only partially on the primary key `(OrderNo, ItemNo)`
must be moved into separate relations. Work out the decomposition on paper first,
then fill in the table below.

**Result (fill in):**

| Relation       | Attributes                                         | Primary Key            |
|----------------|----------------------------------------------------|------------------------|
| `customer`     | `cust_no`, `cust_name`, `cust_city`               | `cust_no`              |
| `vehicle`      | `plate`, `make`, `model`, `year`, `cust_no`       | `plate`                |
| `mechanic`     | `mech_id`, `mech_name`, `hourly_rate`             | `mech_id`              |
| `order`        | `order_no`, `date`, `plate`, `cust_no`            | `order_no`             |
| `work_item`    | `order_no`, `item_no`, `mech_id`, `description`, `hours` | `(order_no, item_no)` |

Check: In every relation, does each non-key attribute depend on the **complete**
primary key?

> *Your check:* Yes, every non-key attribute now depends on the complete primary key of its own relation.
For example, in work_item, description, hours, and mech_id depend on the full key (order_no, item_no), not only on order_no.


### Task 2b – Decompose into 3NF

Examine `order` and `vehicle` for transitive dependencies.

- In `order`: does `cust_no` depend directly on `order_no`? Does `cust_name`
  transitively depend on it through `cust_no`? *(After the 2NF split,
  `cust_name` should already be in `customer` — verify that this is correct.)*
- In `vehicle`: is there a dependency between `plate` and `cust_no` that
  requires a further split, or is `vehicle` already in 3NF?

State your conclusion: are all five relations from Task 2a already in 3NF?
If not, perform the missing decomposition.

> *Your analysis and any further decomposition:*
> The five relations are already acceptable in 3NF if cust_no in "order" represents the customer responsible for that specific repair order.
•	In customer, cust_no determines cust_name and cust_city.
•	In vehicle, plate determines make, model, year, and cust_no.
•	In mechanic, mech_id determines mech_name and hourly_rate.
•	In "order", order_no determines date, plate, and the responsible cust_no.
•	In work_item, (order_no, item_no) determines mech_id, description, and hours.
So no further decomposition is necessary.


### Task 2c – Verify Losslessness

Pick one of the decompositions you performed (e.g. the split of the original
table into `order` and `vehicle`) and verify it using the **Heath criterion**:

$$R_1 \cap R_2 \rightarrow R_1 \setminus R_2 \quad \text{or} \quad R_1 \cap R_2 \rightarrow R_2 \setminus R_1$$

Name the shared attributes, state the FD you rely on, and conclude whether the
decomposition is lossless.

> *Your verification:*Example: split between customer and vehicle.
Let:
R1 = customer(cust_no, cust_name, cust_city)
R2 = vehicle(plate, make, model, year, cust_no)
Shared attribute:
R1 ∩ R2 = {cust_no}
Functional dependency:
cust_no → cust_name, cust_city
This means:
R1 ∩ R2 → R1 \ R2
Therefore, according to Heath’s criterion, the decomposition is lossless.


### Questions for Task 2

**Question 2.1:** Why must `cust_no` remain as a foreign key in `order` even
though the customer is also reachable via the vehicle's licence plate?
Describe a realistic scenario where the direct link `order → customer` is
necessary.

> *Your answer:
> *cust_no should remain in "order" because the customer responsible for an order is not always necessarily the current owner of the vehicle.
A realistic scenario: a company car may be owned by one customer account, but a different customer or department may pay for a specific repair. Another example is when a vehicle is sold later: the vehicle’s owner may change, but the historical repair order should still show the customer who placed that order at that time.
So the direct relationship:
order → customer
is useful for historical correctness.


**Question 2.2:** Is the schema after the 3NF decomposition also in BCNF?
Justify your answer using the definition: for every non-trivial FD $X \rightarrow Y$,
$X$ must be a superkey.

> *Your answer:*
> Yes, the schema is also in BCNF, assuming the listed dependencies are the intended ones.
For each table, every non-trivial FD has a determinant that is a key:
customer: cust_no is key
vehicle: plate is key
mechanic: mech_id is key
order: order_no is key
work_item: (order_no, item_no) is key
Therefore, every determinant is a superkey, so the schema satisfies BCNF.

**Question 2.3:** The hourly rate of a mechanic is stored in `mechanic`. If a
mechanic changes their rate during the year, what problem arises for already
completed orders? How could the schema be extended to correctly record
historical hourly rates?

> *Your answer:*
> If a mechanic’s hourly rate changes, completed orders may become incorrect because the system would show the new rate instead of the rate that was valid when the work was done.
A better design is to store hourly rate history, for example:
mechanic_rate(mech_id, valid_from, valid_to, hourly_rate)
Then each work item can be connected to the rate that was valid at the time of the order.


---

## 3 – Schema Diagram

### Task 3a – Create the PlantUML File

Create `schema.puml` in the repository directory:

```bash
vim schema.puml
```

> If you have never used Vim, run `vimtutor` in your terminal first — a
> self-contained 30-minute interactive lesson. The essential commands:
> - `i` — enter Insert mode (you can type)
> - `Esc` — return to Normal mode
> - `:w` — save the file
> - `:wq` — save and quit
> - `:q!` — quit without saving

Transfer your normalized schema into PlantUML IE notation. Use the following
skeleton and add the missing attributes and relationships according to your
result from Task 2:

```plantuml
@startuml
!define PK <b><color:gold>PK</color></b>
!define FK <i><color:gray>FK</color></i>

entity customer {
    PK cust_no    : INTEGER
    --
    cust_name     : TEXT
    cust_city     : TEXT
}

entity vehicle {
    PK plate      : TEXT
    --
    FK cust_no    : INTEGER
    make          : TEXT
    model         : TEXT
    year          : INTEGER
}

entity mechanic {
    PK mech_id    : INTEGER
    --
    mech_name     : TEXT
    hourly_rate   : REAL
}

entity order {
    PK order_no   : INTEGER
    --
    FK plate      : TEXT
    FK cust_no    : INTEGER
    date          : DATE
}

entity work_item {
    PK FK order_no : INTEGER
    PK item_no     : INTEGER
    --
    FK mech_id     : INTEGER
    description    : TEXT
    hours          : REAL
}

' Add relationship lines here:
' customer    ||--o{ vehicle    : "owns"
' ...

@enduml
```

Add the missing relationship lines. Every foreign key relationship needs one
line. PlantUML IE multiplicity notation:

| Notation | Meaning |
|----------|---------|
| `\|\|` | exactly one |
| `o{` | zero or many |
| `\|{` | one or many |
| `o\|` | zero or one |

### Task 3b – Render and Review

```bash
plantuml -tsvg schema.puml
```

Open `schema.svg` in a browser and check:
- Are all five entities visible?
- Does every foreign key relationship show the correct multiplicity?
- Are PK and FK correctly marked?

If you are working on the student server, copy the file to your local machine first:

```bash
scp <username>@<server>:/path/to/DBMS_04/schema.svg ~/Downloads/schema.svg
```

> **Screenshot 2:** Take a screenshot showing the rendered diagram with all
> five entities and their relationships.
>
> <img width="451" height="697" alt="Screenshot 2" src="https://github.com/user-attachments/assets/cf796243-eed6-4ad1-8b68-e3cf0c0c0de6" />

### Task 3c – Commit

```bash
git add schema.puml
echo "schema.svg" >> .gitignore
echo "*.db"       >> .gitignore
git add .gitignore
git commit -m "docs: normalized schema diagram for workshop management"
```

---

## 4 – DDL: Implement the Schema in SQLite

### Task 4a – Write schema.sql

```bash
vim schema.sql
```

Write `CREATE TABLE` statements for all five relations. Requirements:

- Every table must have an explicit `PRIMARY KEY` constraint.
- Every foreign key must be declared with `ON DELETE` and `ON UPDATE` actions —
  choose the most restrictive action that is still domain-correct.
- `work_item.hours` must be greater than zero: `CHECK (hours > 0)`.
- `mechanic.hourly_rate` must also be greater than zero.
- Use SQLite types only (`INTEGER`, `TEXT`, `REAL`, `DATE`).

<details>
<summary>Solution skeleton — try it yourself first</summary>

```sql
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
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE mechanic (
    mech_id     INTEGER PRIMARY KEY,
    mech_name   TEXT    NOT NULL,
    hourly_rate REAL    NOT NULL CHECK (hourly_rate > 0)
);

CREATE TABLE "order" (
    order_no INTEGER PRIMARY KEY,
    plate    TEXT    NOT NULL,
    cust_no  INTEGER NOT NULL,
    date     DATE    NOT NULL,
    FOREIGN KEY (plate)   REFERENCES vehicle(plate)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (cust_no) REFERENCES customer(cust_no)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE work_item (
    order_no    INTEGER NOT NULL,
    item_no     INTEGER NOT NULL,
    mech_id     INTEGER NOT NULL,
    description TEXT    NOT NULL,
    hours       REAL    NOT NULL CHECK (hours > 0),
    PRIMARY KEY (order_no, item_no),
    FOREIGN KEY (order_no) REFERENCES "order"(order_no)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (mech_id)  REFERENCES mechanic(mech_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);
```

> Note: `order` is a reserved word in SQL. It must be quoted with double quotes
> in SQLite, or you rename the table to `repair_order` to avoid the conflict
> entirely — which is often the cleaner choice in practice.

</details>

### Task 4b – Load the Schema and Verify

```bash
sqlite3 workshop.db < schema.sql
sqlite3 workshop.db ".tables"
```

> You should see: `customer  mechanic  order  vehicle  work_item`

> **Screenshot 3:** Take a screenshot showing the `.tables` output.
>
> <img width="533" height="79" alt="Screenshot 3" src="https://github.com/user-attachments/assets/fee63f09-7144-453e-963f-d96c40b8d3c4" />


### Task 4c – Insert Sample Data

```bash
vim data.sql
```

Insert the data from the flat table in Section 1, now split across the five
normalized relations. Start with the tables that have no foreign keys
(`customer`, `mechanic`), then `vehicle`, then `order`, and finally `work_item`.

<details>
<summary>Sample data — try it yourself first</summary>

```sql
PRAGMA foreign_keys = ON;

-- Customers
INSERT INTO customer VALUES (1, 'Berger, Franz', 'Bochum');
INSERT INTO customer VALUES (2, 'Novak, Jana',   'Herne');

-- Mechanics
INSERT INTO mechanic VALUES (1, 'Schulz, P.', 60.00);
INSERT INTO mechanic VALUES (3, 'Huber, Tom', 65.00);

-- Vehicles
INSERT INTO vehicle VALUES ('BO-AB 123', 1, 'VW',   'Golf',  2018);
INSERT INTO vehicle VALUES ('HER-XY 44', 2, 'Ford', 'Focus', 2020);
INSERT INTO vehicle VALUES ('BO-CD 999', 1, 'BMW',  '320i',  2019);

-- Orders
INSERT INTO "order" VALUES (1001, 'BO-AB 123', 1, '2026-03-10');
INSERT INTO "order" VALUES (1002, 'HER-XY 44', 2, '2026-03-11');
INSERT INTO "order" VALUES (1003, 'BO-CD 999', 1, '2026-03-12');

-- Work items
INSERT INTO work_item VALUES (1001, 1, 3, 'Oil change',         0.5);
INSERT INTO work_item VALUES (1001, 2, 3, 'Replace air filter', 0.3);
INSERT INTO work_item VALUES (1002, 1, 1, 'Front brake pads',   1.5);
INSERT INTO work_item VALUES (1003, 1, 3, 'Service inspection', 2.0);
INSERT INTO work_item VALUES (1003, 2, 1, 'Tyre change',        0.8);
```

</details>

```bash
sqlite3 workshop.db < data.sql
```

Verify the row counts:

```sql
SELECT 'customer',  COUNT(*) FROM customer
UNION ALL SELECT 'mechanic',  COUNT(*) FROM mechanic
UNION ALL SELECT 'vehicle',   COUNT(*) FROM vehicle
UNION ALL SELECT 'order',     COUNT(*) FROM "order"
UNION ALL SELECT 'work_item', COUNT(*) FROM work_item;
```

> Expected: 2, 2, 3, 3, 5.

Commit:

```bash
git add schema.sql data.sql
git commit -m "feat: DDL and sample data for normalized workshop schema"
```

### Questions for Task 4

**Question 4.1:** `ON DELETE CASCADE` was chosen for the foreign key
`work_item.order_no`, but `ON DELETE RESTRICT` for `vehicle.cust_no`.
Justify both choices in terms of the domain — what does it mean for the
business if an order is deleted versus if a customer is deleted?

> *Your answer:*
> ON DELETE CASCADE is correct for work_item.order_no because work items belong to an order. If an order is deleted, its work items should also disappear because they no longer have meaning without the order.
ON DELETE RESTRICT is correct for vehicle.cust_no because deleting a customer while vehicles still refer to that customer would leave invalid data. The business should first reassign or delete the vehicles before deleting the customer.


**Question 4.2:** Test referential integrity by running:

```sql
PRAGMA foreign_keys = ON;
INSERT INTO work_item VALUES (9999, 1, 3, 'Ghost item', 1.0);
```

What error do you get? What does this tell you about the difference between
a constraint declared in DDL and one that is actually enforced at runtime?

> *Your answer:*
> FOREIGN KEY constraint failed
This shows that declaring a foreign key in DDL is not enough in SQLite unless foreign key enforcement is activated with:
PRAGMA foreign_keys = ON;
So a constraint can exist in the schema, but it must also be enforced at runtime.


**Question 4.3:** Test the CHECK constraint:

```sql
INSERT INTO work_item VALUES (1001, 3, 3, 'Invalid', -0.5);
```

What happens? What would happen if the CHECK constraint were missing?

> *Your answer:*
> CHECK constraint failed
This happens because hours must be greater than zero.
If the CHECK constraint were missing, SQLite would allow negative hours, which would be logically wrong for a repair task and could produce incorrect invoices.


---

## 5 – SQL Queries

Save all three queries in a file called `queries.sql`. Write a short comment
before each query describing its purpose.

### Task 5a – All Work Items for a Given Customer

**Task:** List all order numbers, order dates, licence plates, item descriptions,
and hours for customer `Berger, Franz`, ordered by date and item number.

Write the relational algebra expression first (in words or formal notation),
then the SQL query.

```sql
-- First select the customer whose name is 'Berger, Franz'.
-- Then join this customer with orders, vehicles, and work items.
-- Finally project order number, date, plate, description, and hours.


SELECT
    o.order_no,
    o.date,
    v.plate,
    wi.description,
    wi.hours
FROM customer c
JOIN "order" o ON c.cust_no = o.cust_no
JOIN vehicle v ON o.plate = v.plate
JOIN work_item wi ON o.order_no = wi.order_no
WHERE c.cust_name = 'Berger, Franz'
ORDER BY o.date, wi.item_no;
Query 5a: insert here
```

<details>
<summary>Expected result</summary>

Four rows: two items from order 1001 (Golf, 2026-03-10) and two items from
order 1003 (BMW 320i, 2026-03-12).

</details>

**Question 5a:** This query joins four tables (`customer`, `order`, `vehicle`,
`work_item`). In what order would the query optimizer ideally perform the joins —
and why does the join order not affect the *result*, but does affect *performance*?

> *Your answer:*
> The optimizer would ideally start with the most selective condition:
WHERE c.cust_name = 'Berger, Franz'
Then it can join only that customer’s rows with "order", vehicle, and work_item.
The join order does not affect the final result for inner joins because inner joins are associative and commutative. However, it affects performance because joining smaller filtered tables first reduces the amount of intermediate data.


---

### Task 5b – Total Hours per Mechanic in March 2026

**Task:** For each mechanic, compute the sum of all hours worked on orders whose
date falls in March 2026. Show `mech_name`, `total_hours` (rounded to one decimal
place), and `orders` (the number of distinct orders in which the mechanic had at
least one work item). Sort descending by `total_hours`.

```sql
-- SELECT
    m.mech_name,
    ROUND(SUM(wi.hours), 1) AS total_hours,
    COUNT(DISTINCT wi.order_no) AS orders
FROM mechanic m
JOIN work_item wi ON m.mech_id = wi.mech_id
JOIN "order" o ON wi.order_no = o.order_no
WHERE o.date >= '2026-03-01'
  AND o.date < '2026-04-01'
GROUP BY m.mech_id, m.mech_name
ORDER BY total_hours DESC;

```

<details>
<summary>Expected result</summary>

| mech_name  | total_hours | orders |
|------------|-------------|--------|
| Huber, Tom | 2.8         | 2      |
| Schulz, P. | 2.3         | 2      |

</details>

**Question 5b:** Using `COUNT(DISTINCT order_no)` counts orders, not items.
What would `COUNT(*)` count instead, and why would the result differ in this
case?

> *Your answer:*
> COUNT(DISTINCT order_no) counts how many different orders each mechanic worked on.
COUNT(*) would count the number of work item rows. The result can differ because one mechanic may work on multiple items in the same order. For example, Huber worked on two items in order 1001, but that still counts as only one distinct order.


---

### Task 5c – Vehicles with No Repair Order

**Task:** Return the licence plate and model of every vehicle for which
**no** order exists in the database.

Use a set-difference approach with `EXCEPT` and also write an alternative using
`NOT EXISTS`.

```sql
-- Variant 1: EXCEPT
-- Query 5c-1:
  SELECT
    plate,
    model
FROM vehicle

EXCEPT

SELECT
    v.plate,
    v.model
FROM vehicle v
JOIN "order" o ON v.plate = o.plate;


-- Variant 2: NOT EXISTS
-- Query 5c-2:
   SELECT
    v.plate,
    v.model
FROM vehicle v
WHERE NOT EXISTS (
    SELECT 1
    FROM "order" o
    WHERE o.plate = v.plate
);



```

<details>
<summary>Expected result</summary>

With the data from Task 4c there are no matches — all three vehicles have at
least one order. Insert a fourth vehicle without an order to test the query:

```sql
INSERT INTO vehicle VALUES ('BOT-ZZ 1', 1, 'Toyota', 'Yaris', 2022);
```

After that, the query should return `BOT-ZZ 1 | Yaris`.

</details>

**Question 5c:** `EXCEPT` and `NOT EXISTS` are logically equivalent — they
always produce the same result. Are there situations where one approach should
be preferred in practice? Consider readability and extensibility.

> *Your answer:*
> EXCEPT is useful when the query is simple and clearly expresses set difference: “all vehicles minus vehicles with orders.”
NOT EXISTS is often preferred in practice when the condition becomes more complex, because it is easier to extend with additional filters. For example, checking vehicles with no orders after a certain date is clearer with NOT EXISTS.


---

Commit:

```bash
git add queries.sql
git commit -m "feat: three SQL queries on normalized workshop schema"
```

---

## 6 – Reflection

**Question A – Normalization and redundancy:**  
The original flat table had 5 rows and 15 columns. The normalized schema has
5 tables. At which data volume does normalization pay off most — at 5 rows or
at 50,000? Justify with concrete reference to the anomalies from Task 1a.

> *Your answer:*
> Normalization pays off much more at 50,000 rows than at 5 rows.
With only 5 rows, redundancy is visible but manageable. With 50,000 rows, update anomalies become serious. For example, if a mechanic’s hourly rate changes, thousands of rows might need updates. Insert anomalies also become a bigger problem because the system cannot store new customers, vehicles, or mechanics independently. Delete anomalies also become dangerous because deleting one order could accidentally remove the only stored information about a customer, vehicle, or mechanic.


**Question B – 3NF vs. BCNF:**  
Lecture 04 explains that BCNF is not always dependency-preserving. Is this
relevant for the workshop schema? Would a BCNF decomposition have looked
different from the 3NF decomposition here?

> *Your answer:*
> In this workshop schema, BCNF does not create a major issue because the final relations already have determinants that are keys.
For example:
cust_no → cust_name, cust_city
plate → make, model, year, cust_no
mech_id → mech_name, hourly_rate
order_no → date, plate, cust_no
(order_no, item_no) → description, hours, mech_id
Each determinant is a key in its relation. Therefore, a BCNF decomposition would not look different from the 3NF decomposition here.


**Question C – Redundant foreign key in `order`:**  
`order` contains both `plate` (FK → `vehicle`) and `cust_no` (FK → `customer`).
Since `vehicle` itself contains `cust_no`, one might argue that `cust_no`
in `order` is redundant and violates 3NF. Is that correct? When would such
a deliberate denormalization be justified?

> *Your answer:*
> It depends on the meaning of cust_no.
If order.cust_no is only copied from vehicle.cust_no, then it is redundant because the customer can already be reached through the vehicle.
But if order.cust_no means “the customer responsible for this repair order,” then it is justified. This is useful when the payer is different from the vehicle owner, or when vehicle ownership changes later but old orders must keep their original customer information.
This is a deliberate denormalization or business-driven design choice. It can be justified for historical accuracy and easier querying.


**Question D – NULL and order status:**  
An order that has just been created may have no work items yet. What does the
current schema say about this case? Would the schema need to be extended to
correctly represent an order's status (open / completed)? Sketch the necessary
change.

> *Your answer:*
> The current schema allows an order to exist without work items, because "order" is independent from work_item. So a newly created order can be stored first, and work items can be added later.
However, the schema does not explicitly say whether the order is open or completed. To represent this better, we can add a status column:
ALTER TABLE "order"
ADD COLUMN status TEXT CHECK (status IN ('open', 'completed', 'cancelled'));
A better full design would be:
CREATE TABLE "order" (
    order_no INTEGER PRIMARY KEY,
    plate    TEXT NOT NULL,
    cust_no  INTEGER NOT NULL,
    date     DATE NOT NULL,
    status   TEXT NOT NULL CHECK (status IN ('open', 'completed', 'cancelled')),
    FOREIGN KEY (plate) REFERENCES vehicle(plate)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (cust_no) REFERENCES customer(cust_no)
        ON DELETE RESTRICT ON UPDATE CASCADE
);


> **Screenshot 4:** Take a screenshot showing the output of Query 5b directly
> in `sqlite3` (with `.headers on` and `.mode column` activated).
>
> <img width="415" height="319" alt="Screenshot 4" src="https://github.com/user-attachments/assets/fc047fc0-ba60-4e8d-a924-cd9dc8622127" />


---

## Bonus Tasks

1. **Hourly rate history:** Design a schema extension that allows recording a
   mechanic's hourly rate historically — i.e. which rate applied at the time a
   specific order was processed. Write the modified `CREATE TABLE` statements.

2. **Spare parts:** The workshop also charges for parts in addition to labour.
   Extend the schema with a `part` table and a `order_part` join table that
   records which parts were used in which order. Maintain normal form and
   referential integrity.

3. **Total invoice per order:** Write a query that computes the total amount for
   each order: the sum of `hours × hourly_rate` across all work items. Which
   tables need to be joined?

4. **GitHub Actions:** Add a workflow file `.github/workflows/release.yml` that
   installs PlantUML, renders `schema.puml` to `schema.svg`, and publishes it
   as a release artifact on every `v*` tag. Trigger a release with
   `git tag v1.0.0 && git push --tags`.

---

## Further Reading

- E. F. Codd (1972): *Further Normalization of the Data Base Relational Model.* In: Rustin (ed.): Data Base Systems.
- [SQLite – CHECK Constraints](https://www.sqlite.org/lang_createtable.html#check_constraints)
- [SQLite – Foreign Key Support](https://www.sqlite.org/foreignkeys.html)
- [PlantUML – Entity Relationship Diagram](https://plantuml.com/ie-diagram)
- Lecture 04 handout – *Normalization*
