# IoT Network Attack Classification

Classifying IoT network traffic into attack types using a Dense Neural Network and a Random Forest Classifier, built and compared end-to-end in a single notebook.

## Overview

IoT devices generate network traffic that can be mined to detect malicious activity. This project takes a labeled IoT network traffic dataset and builds a full machine learning pipeline — from raw Excel data to a trained, evaluated multi-class classifier — using two different modeling approaches so their performance can be compared directly.

## Dataset

- **Source:** [Kaggle](https://www.kaggle.com/) — IoT network traffic dataset
- **Format:** Excel workbook (`.xlsx`)
- **Size:** 123,117 rows × 92 features (after preprocessing)
- **Target:** `Attack_type` (multi-class label)
- **Features:** Flow-level network statistics (packet counts, header sizes, flag counts, idle/active time stats, window sizes, protocol, service, etc.)

## Workflow

1. **Data Importing** — Load the raw dataset with `pandas`.
2. **Exploratory Data Analysis** — Check skewness, visualize distributions per attack type with boxplots, and examine feature correlations.
3. **Model Selection** — Choose models robust to the outliers and multicollinearity observed in EDA.
4. **Data Preparation** — Encode categorical features (one-hot), scale numerical features (standard scaling), and split into train/validation sets (80/20).
5. **Modeling** — Train a Dense Neural Network and a Random Forest Classifier (tuned via `RandomizedSearchCV`).
6. **Evaluation** — Compare both models on validation accuracy.

## Tech Stack

| Category | Tools |
|---|---|
| Data handling | `pandas`, `numpy` |
| Visualization | `matplotlib`, `seaborn` |
| Preprocessing | `scikit-learn` (`ColumnTransformer`, `OneHotEncoder`, `StandardScaler`, `LabelEncoder`) |
| Deep Learning | `TensorFlow` / `Keras` |
| Classical ML | `scikit-learn` (`RandomForestClassifier`, `RandomizedSearchCV`) |

## Exploratory Data Analysis

- Numeric features show heavy right-skew, with several columns exhibiting extreme skewness (e.g., `flow_duration`, `fwd_pkts_tot`), indicating a large number of outliers.
- Boxplots grouped by `Attack_type` show that outlier patterns differ by attack type, suggesting these features carry discriminative signal for classification.
- The correlation matrix reveals several strongly correlated feature pairs (correlation > 0.5), motivating the choice of models that are robust to multicollinearity.

## Models

### 1. Dense Neural Network

A feed-forward network with Batch Normalization and Dropout, trained with the Nadam optimizer.

**Architecture**

| Layer | Units | Activation | Notes |
|---|---|---|---|
| Dense | 256 | ReLU | + BatchNormalization |
| Dense | 128 | ReLU | + BatchNormalization |
| Dense | 64 | ReLU | + BatchNormalization |
| Dense | 32 | ReLU | + Dropout (0.2) |
| Dense (output) | n_classes | Softmax | |

**Training configuration:** Nadam optimizer (lr = 0.001), sparse categorical crossentropy loss, batch size 32, 8 epochs.

**Training results**

| Epoch | Train Accuracy | Train Loss | Val Accuracy | Val Loss |
|---|---|---|---|---|
| 1 | 97.63% | 0.0895 | 96.22% | 0.0951 |
| 2 | 98.86% | 0.0391 | 99.29% | 0.0337 |
| 3 | 99.04% | 0.0315 | 99.09% | 0.0317 |
| 4 | 99.15% | 0.0283 | 99.25% | 0.0288 |
| 5 | 99.20% | 0.0265 | 98.07% | 0.0402 |
| 6 | 99.26% | 0.0246 | 99.19% | 0.0240 |
| 7 | 99.30% | 0.0231 | **99.39%** | **0.0217** |
| 8 | 99.31% | 0.0220 | 99.22% | 0.0328 |

The model converges quickly, surpassing 99% validation accuracy by epoch 2 and remaining stable through training, with minimal signs of overfitting.

### 2. Random Forest Classifier

Tuned via `RandomizedSearchCV` (2-fold CV, 5 parameter combinations sampled) over `n_estimators`, `max_depth`, `min_samples_split`, `min_samples_leaf`, `max_features`, `criterion`, `class_weight`, and `max_leaf_nodes`.

| Metric | Value |
|---|---|
| Best CV accuracy (search) | 99.47% |
| Validation accuracy (held-out) | 99.62% |

## Results Summary

| Model | Validation Accuracy | Validation Loss |
|---|---|---|
| Dense Neural Network | 99.22% | 0.0328 |
| Random Forest Classifier | **99.62%** | — |

Both models achieve strong, comparable performance on this task, with the Random Forest Classifier edging out the neural network on final validation accuracy.

## Repository Structure

```
.
├── attack_dense.ipynb   # Full pipeline: EDA, preprocessing, modeling, evaluation
└── README.md
```

## Getting Started

1. Clone the repository and install dependencies:
   ```bash
   pip install pandas numpy matplotlib seaborn scikit-learn tensorflow openpyxl
   ```
2. Update the dataset path in the notebook to point to your local copy of the Excel file.
3. Run `attack_dense.ipynb` top to bottom.

## License

This project is provided for educational and portfolio purposes.
