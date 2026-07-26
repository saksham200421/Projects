# California House Price Prediction

![Python](https://img.shields.io/badge/Python-3.10%2B-blue)
![License](https://img.shields.io/badge/License-Educational-lightgrey)

Predicting median house value for California census districts using engineered geographic and income features, comparing a Dense Neural Network, a Random Forest Regressor, and XGBoost, built and compared end-to-end in a single notebook.

## Table of Contents

- [Key Results](#key-results)
- [Overview](#overview)
- [Dataset](#dataset)
- [Workflow](#workflow)
- [Tech Stack](#tech-stack)
- [Exploratory Data Analysis](#exploratory-data-analysis)
- [Feature Engineering](#feature-engineering)
- [Models](#models)
- [Results Summary](#results-summary)
- [Limitations & Future Work](#limitations--future-work)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
- [License](#license)

## Key Results

| Model | R² | MAE |
|---|---|---|
| Neural Network | **0.76** | $35,455 |
| Random Forest | **0.86** | $31,324 |
| XGBoost | **0.87** | **$27,100** |


Both tree-based models outperform the neural network. Random Forest has the better R² (explains more variance overall); XGBoost has the better MAE (smaller typical dollar error) and R² out of all — see [Results Summary](#results-summary) for the full comparison.

## Overview

This project is a regression task: predicting `median_house_value` for California housing districts using the classic 1990 census-based California Housing dataset. Each row represents a census block group (not an individual house) — features like `total_rooms`, `population`, and `households` are aggregates for that district.

The pipeline explores which raw features actually relate to price, engineers new features to fill in the gaps (geographic clustering, income buckets), and compares three modeling approaches — a neural network, a Random Forest, and XGBoost — to find the best predictor.

## Dataset

- **Source:** California Housing dataset (1990 U.S. census), based on Pace & Barry (1997)
- **Format:** CSV
- **Size:** ~17,000 rows × 9 raw features
- **Target:** `median_house_value` (continuous, right-skewed)
- **Features:** `longitude`, `latitude`, `housing_median_age`, `total_rooms`, `total_bedrooms`, `population`, `households`, `median_income`

## Workflow

1. **Data Importing** — Load the raw dataset with `pandas`.
2. **Exploratory Data Analysis** — Check feature-target correlations, skewness, and outlier distributions via scatter plots, skewness bar charts, and boxplots.
3. **Feature Engineering** — Since raw `longitude`/`latitude` show little direct correlation with price, engineer geographic and income features (see [Feature Engineering](#feature-engineering)).
4. **Data Preparation** — Scale numeric features with `StandardScaler` (fit on train only), and apply a `log1p` transform to the target to reduce skew.
5. **Modeling** — Train a Dense Neural Network, a Random Forest Regressor, and an XGBoost Regressor, tuning the latter two via `RandomizedSearchCV`.
6. **Evaluation** — Compare all three models on MAE and R² (converted back from log scale to dollar terms).

## Tech Stack

| Category | Tools |
|---|---|
| Data handling | `pandas`, `numpy` |
| Visualization | `matplotlib`, `seaborn` |
| Preprocessing | `scikit-learn` (`StandardScaler`, `FunctionTransformer`, `KMeans`) |
| Deep Learning | `TensorFlow` / `Keras` |
| Classical ML | `scikit-learn` (`RandomForestRegressor`, `RandomizedSearchCV`), `XGBoost` (`XGBRegressor`) |

## Exploratory Data Analysis

- `median_income` shows by far the strongest relationship with `median_house_value` among the raw features; all others, including raw coordinates, show weak or unclear linear patterns on their own.
- Several features (`total_rooms`, `total_bedrooms`, `population`) are heavily right-skewed, motivating scaling and a log-transformed target.
- Bucketing `median_income` reveals the data is concentrated in the `Medium` range, with far fewer districts at either income extreme.

## Feature Engineering

Raw geographic coordinates carry a lot of signal (location drives price) but aren't usable directly by most models, since price doesn't vary linearly with longitude/latitude. To fix this:

- **K-Means clustering** is fit on `longitude`/`latitude` from the training set only (cluster count chosen via the elbow method on WCSS/inertia).
- Each district's **distance to every cluster centroid** becomes a feature, giving the model a continuous, usable geographic signal instead of two raw, hard-to-interpret coordinates.
- `median_income` is additionally bucketed into `Low` / `Medium` / `High` / `Very High` categories.

## Models

### 1. Dense Neural Network

A feed-forward network with Batch Normalization and Dropout, trained with the Adam optimizer and Huber loss.

**Architecture**

| Layer | Units | Activation | Notes |
|---|---|---|---|
| Dense | 64 | ReLU | |
| Dense | 32 | ReLU | + BatchNormalization |
| Dense (output) | 1 | Linear | |

**Training configuration:** Adam optimizer (lr = 0.004), Huber loss, batch size 32, up to 100 epochs with `EarlyStopping` and `ReduceLROnPlateau` on validation loss.

**Result:** Validation MAE ≈ **$35,455**.

### 2. Random Forest Regressor

Tuned via `RandomizedSearchCV` (3-fold CV, 10 parameter combinations sampled) over `n_estimators`, `max_depth`, `min_samples_split`, `min_samples_leaf`, `max_features`, `ccp_alpha`, and `max_samples`, scored on negative MAE.

| Metric | Value |
|---|---|
| Best CV MAE (search) | $31,325 |
| Validation R² | **0.858** |

### 3. XGBoost Regressor

Tuned via `RandomizedSearchCV` (3-fold CV, 30 parameter combinations sampled) over `n_estimators`, `max_depth`, `learning_rate`, `subsample`, `colsample_bytree`, `colsample_bylevel`, `min_child_weight`, `gamma`, `reg_alpha`, and `reg_lambda`.

| Metric | Value |
|---|---|
| Validation MAE | **$27,107** |
| Validation R² | 0.869 |

## Results Summary

| Model | R² | MAE |
|---|---|---|
| Neural Network | **0.76** | $35,455 |
| Random Forest | **0.86** | $31,324 |
| XGBoost | **0.87** | **$27,100** |

The two tree-based ensembles clearly outperform the neural network, consistent with tree-based models generally having an edge on small-to-medium structured/tabular datasets like this one. Between Random Forest and XGBoost, the result is : XGBoost achieves the higher R² (explaining more overall variance) and a lower MAE (smaller typical dollar error) — which one is "better" the all other model we used in our project.

## Limitations & Future Work

- Potential next steps: try stacking/ensembling the three models, tune the neural network architecture further (it currently underperforms both tree-based models), and experiment with the cluster count (`k`) used in geographic feature engineering.

## Repository Structure

```
.
├── california_house_price_pred_tf.ipynb   # Full pipeline: EDA, feature engineering, modeling, evaluation
└── README.md
```

## Getting Started

1. Clone the repository and install dependencies:
   ```bash
   pip install pandas numpy matplotlib seaborn scikit-learn tensorflow xgboost
   ```
2. Update the dataset path in the notebook to point to your local copy of `california_housing_train.csv`.
3. Run `california_house_price_pred_tf.ipynb` top to bottom.

---

This project is provided for educational and portfolio purposes.
