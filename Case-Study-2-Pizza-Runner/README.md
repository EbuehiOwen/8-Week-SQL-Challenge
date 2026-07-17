# 🍕 Case Study #2 - Pizza Runner
> Part of the [8 Week SQL Challenge](https://8weeksqlchallenge.com/) by [Danny Ma](https://www.linkedin.com/in/datawithdanny/)

---

## 📌 Overview
Danny launched Pizza Runner, a pizza delivery service that combines fresh pizza with an Uber-style delivery network of runners. This case study explores operational data to help Danny better understand his business performance across orders, deliveries, ingredients and revenue.

**Tools used:** PostgreSQL, Power BI  
**Concepts:** Data Cleaning, CTEs, JOINs, Window Functions, Aggregations, UNNEST, String Manipulation, Table Design, Data Visualization

---

## 📊 Dashboard Preview

A 3-page interactive Power BI dashboard visualizing the SQL analysis:

**Page 1 — Pizza Metrics**
![Pizza Metrics Dashboard](./Page%201%20-%20Pizza%20Metrics.png)

**Page 2 — Runner & Customer Experience**
![Runner Experience Dashboard](./Page%202%20-%20Runner%20Experience.png)

**Page 3 — Revenue & Insights**
![Revenue Insights Dashboard](./Page%203%20-%20Revenue%20Insights.png)

> Download the [interactive report](./pizza_runner_dashboard.pbix) to explore it in Power BI Desktop.

---

## 🗄️ Database Schema

Six tables:

- **runners** — runner registration details
- **customer_orders** — pizza orders placed by customers
- **runner_orders** — delivery details per order
- **pizza_names** — pizza type names
- **pizza_recipes** — toppings for each pizza type
- **pizza_toppings** — topping id to name mapping

---

## 🧹 Data Cleaning

Before analysis, two tables required significant cleaning:

**customer_orders** — `exclusions` and `extras` columns contained empty strings and text `'null'` values instead of proper NULLs.

**runner_orders** — `pickup_time`, `distance`, `duration` and `cancellation` columns all contained text `'null'` values. Additionally `distance` had inconsistent formats (`'20km'`, `'23.4 km'`, `'23.4'`) and `duration` had inconsistent formats (`'32 minutes'`, `'25mins'`, `'40'`).

Both were cleaned into permanent tables (`clean_customer_orders` and `clean_runner_orders`) using CASE WHEN for NULL handling and REGEXP_REPLACE to standardize numeric columns.

---

## 💡 Solutions & Results

### Section A — Pizza Metrics

**Q1: How many pizzas were ordered?**
| total_pizzas_ordered |
|---|
| 14 |

---

**Q2: How many unique customers placed orders?**
| unique_customers |
|---|
| 5 |

---

**Q3: How many successful orders were delivered by each runner?**
| runner_id | successful_deliveries |
|---|---|
| 1 | 4 |
| 2 | 3 |
| 3 | 1 |

---

**Q6: What was the maximum number of pizzas in a single order?**
| order_id | max_pizza_count |
|---|---|
| 4 | 3 |

---

**Q8: How many pizzas were delivered with both exclusions AND extras?**
| changed_pizza |
|---|
| 1 |

---

**Q9: What was the total volume of pizzas ordered for each hour of the day?**
| order_hour | count |
|---|---|
| 11 | 1 |
| 13 | 3 |
| 18 | 3 |
| 19 | 1 |
| 21 | 3 |
| 23 | 3 |

---

**Q10: What was the volume of orders for each day of the week?**
| order_weekday | total_volume |
|---|---|
| Wednesday (3) | 5 |
| Thursday (4) | 3 |
| Friday (5) | 1 |
| Saturday (6) | 5 |

---

### Section B — Runner and Customer Experience

**Q1: How many runners signed up each week?**
| week | signups |
|---|---|
| 1 | 2 |
| 2 | 1 |
| 3 | 1 |

---

**Q2: What was the average time for each runner to arrive at HQ for pickup?**
| runner_id | avg_pickup_minutes |
|---|---|
| 1 | 15.68 |
| 2 | 23.72 |
| 3 | 10.47 |

---

**Q3: Is there a relationship between number of pizzas and prep time?**
| pizza_count | avg_prep_time |
|---|---|
| 1 | 12.4 |
| 2 | 18.4 |
| 3 | 29.3 |

> 📊 **Insight:** There is a clear positive relationship between order size and prep time. Each additional pizza adds roughly 8-10 minutes of prep time. Order 8 is a notable outlier with a single pizza taking 20 minutes, compared to the usual 10-11 minutes, suggesting a possible kitchen delay.

---

**Q4: What was the average distance travelled per customer?**
| customer_id | avg_distance_km |
|---|---|
| 101 | 20.0 |
| 102 | 16.7 |
| 103 | 23.4 |
| 104 | 10.0 |
| 105 | 25.0 |

> 📊 **Insight:** Customer 104 lives closest to the restaurant at 10km while Customer 105 lives furthest at 25km.

---

**Q5: What was the difference between longest and shortest delivery times?**
| delivery_diff |
|---|
| 30 minutes |

---

**Q6: What was the average speed for each runner per delivery?**
| runner_id | order_id | distance | duration | speed_kmh |
|---|---|---|---|---|
| 1 | 1 | 20 | 32 | 37.50 |
| 1 | 2 | 20 | 27 | 44.44 |
| 1 | 3 | 13.4 | 20 | 40.20 |
| 1 | 10 | 10 | 10 | 60.00 |
| 2 | 4 | 23.4 | 40 | 35.10 |
| 2 | 7 | 25 | 25 | 60.00 |
| 2 | 8 | 23.4 | 15 | 93.60 |
| 3 | 5 | 10 | 15 | 40.00 |

> ⚠️ **Data Quality Flag:** Runner 2's speed on Order 8 is 93.60 km/h which is suspiciously high compared to all other deliveries. This may indicate a data entry error and warrants further investigation.

---

**Q7: What is the successful delivery percentage for each runner?**
| runner_id | success_pct |
|---|---|
| 1 | 100% |
| 2 | 75% |
| 3 | 50% |

> 📊 **Insight:** Runner 1 has a perfect delivery record. Runner 3's 50% rate is based on only 2 orders so limited conclusions can be drawn from this small sample.

---

### Section C — Ingredient Optimisation

**Q1: What are the standard ingredients for each pizza?**
| pizza_name | standard_ingredients |
|---|---|
| Meatlovers | Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| Vegetarian | Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce |

---

**Q2: What was the most commonly added extra?**
| topping_name | count |
|---|---|
| Bacon | 4 |

---

**Q3: What was the most common exclusion?**
| topping_name | count |
|---|---|
| Cheese | 4 |

> 📊 **Insight:** Interestingly, Bacon is the most requested extra while Cheese is the most excluded topping. Danny could consider offering a Bacon-heavy, no-cheese pizza variant to cater to this preference.

---

### Section D — Pricing and Ratings

**Q1: Total revenue with no extras charge**
| total_revenue |
|---|
| $138 |

---

**Q2: Total revenue with $1 charge per extra**
| base_total | extras_total | grand_total |
|---|---|---|
| $138 | $4 | $142 |

---

**Q5: Revenue after paying runners $0.30 per km**
| actual_revenue |
|---|
| $94.44 |

> 📊 **Insight:** After paying runners, Pizza Runner retains $94.44 of the $138 total revenue — a profit margin of approximately 68.4%. Runner costs account for $43.56 (31.6% of revenue). This is a healthy margin for a food delivery business, though scaling delivery distances could significantly impact profitability.

---

## 🔑 Key Business Insights

1. 🍕 **Meatlovers dominates** — it was the most ordered pizza across all customers
2. ⏱️ **Prep time scales with order size** — roughly 8-10 additional minutes per extra pizza
3. ⚠️ **Order 8 prep time anomaly** — single pizza took 20 mins vs usual 10-11 mins, possible kitchen issue
4. 🚗 **Runner 2 speed anomaly** — 93.60 km/h on Order 8 is suspiciously high, possible data error
5. ✅ **Runner 1 is the most reliable** — 100% successful delivery rate
6. 🥓 **Bacon is the favourite extra, Cheese the most excluded** — potential menu opportunity
7. 💰 **68.4% profit margin** after runner payments — healthy but sensitive to delivery distance increases

---

## 📂 Files
| File | Description |
|---|---|
| `solution.sql` | All query solutions including data cleaning |
| `pizza_runner_dashboard.pbix` | Interactive Power BI report (3 pages) |
| `Page 1 - Pizza Metrics.png` | Dashboard page 1 screenshot |
| `Page 2 - Runner Experience.png` | Dashboard page 2 screenshot |
| `Page 3 - Revenue Insights.png` | Dashboard page 3 screenshot |

---

*Challenge created by [Danny Ma](https://8weeksqlchallenge.com/) | Solutions by [Owen Ebuehi](https://www.linkedin.com/in/owenebuehi)*
