# Fire & Smoke Scene Classification

A transfer-learning image classifier that identifies whether a scene contains fire and/or smoke. Built with TensorFlow/Keras on top of a frozen-then-fine-tuned **EfficientNetB4** backbone, trained on the **FASDD_CV** (Flame And Smoke Detection Dataset) benchmark.

The end goal of this project is a lightweight scene classifier that can sit behind a live camera feed and raise an alert when fire is detected — this notebook covers the model training and evaluation stage.

## Hosted

**[Predict Fire](https://fire-detection-api-htan.onrender.com/predict)** - The model is first containerized using docker and published at docker repository and then hosted using render as a API service. The image can be attached in the `form-data` of the request and service might take 1-2 minutes to wake up due to free tier restrictions. Only one image can be sent per request

## Problem

Early detection of fire is critical for preventing property damage and loss of life. Rather than training a CNN from scratch (which needs a large labeled dataset and heavy compute), this project uses transfer learning on an ImageNet-pretrained EfficientNetB4 backbone, adapting it to fire/smoke scene classification.

## Dataset

- **Source:** [FASDD_CV](https://www.kaggle.com/datasets/yuulind/fasdd-cv-coco) — the Computer Vision subset of the FASDD (Flame And Smoke Detection Dataset) benchmark.
- **Labels:** derived from the FASDD filename prefix convention (`Fire`, `Smoke`, `FireAndSmoke`, `NeitherFireNorSmoke`) and collapsed into 3 classes for this task:

| Class | Meaning | Source prefixes |
|---|---|---|
| `0` | smoke present | `Smoke` |
| `1` | Both fire and smoke present | `FireAndSmoke` |
| `2` | No fire or smoke | `NeitherFireNorSmoke` |

- Images are loaded lazily via `tf.data` (`tf.io.read_file` → decode → resize to `300x300` → cast to float32), batched (32), and prefetched for efficient training.
- The model was trained on an 80/20 split of the FASDD_CV `train` folder, and evaluated separately on FASDD_CV's dedicated `val` folder.

## Approach

Two-phase transfer learning on **EfficientNetB4** (ImageNet weights, `include_top=False`):

**Custom classification head**

```
Input (300, 300, 3)
  → RandomContrast(0.15)              # augmentation
  → EfficientNetB4 (frozen initially)
  → GlobalAveragePooling2D
  → Dense(64, relu) → Dropout(0.5)
  → Dense(32, relu) → Dropout(0.3)
  → Dense(3, softmax)
```

**Phase 1 — Feature extraction**
Backbone fully frozen; only the custom head is trained.
- Optimizer: Adam, `lr=1e-3`
- Loss: sparse categorical crossentropy
- 10 epochs
- Result: train accuracy 92.5%, val accuracy 92.9%

**Phase 2 — Fine-tuning**
Last 40 layers of the backbone unfrozen; rest stays frozen.
- Optimizer: Adam, `lr=5e-5`
- 15 epochs
- Result: train accuracy 99.2%, val accuracy 95.4% (train/val gap widens in later epochs — some overfitting as fine-tuning progresses)

Both phases use:
- `ModelCheckpoint` — saves `best_model.keras`, keeping the checkpoint with the lowest `val_loss`
- `ReduceLROnPlateau` — halves the learning rate if `val_loss` plateaus for 5 epochs

The fully trained model (final-epoch weights) is separately exported as `EfficientNetB4_fd.keras`.

## Results

Evaluated on FASDD_CV's validation split (15,884 images):

| Metric | Score |
|---|---|
| Accuracy | 95.3% |
| Precision (weighted) | 0.952 |
| Recall (weighted) | 0.953 |
| F1-score (weighted) | 0.952 |
| ROC-AUC | 0.994 |

**Per-class:**

| Class | Precision | Recall | F1 | Support |
|---|---|---|---|---|
| 0 — Smoke | 0.93 | 0.95 | 0.94 | 5,993 |
| 1 — Both | 0.92 | 0.89 | 0.91 | 3,358 |
| 2 — Neither | 0.99 | 0.99 | 0.99 | 6,533 |

**Confusion matrix:**

|  | Pred 0 | Pred 1 | Pred 2 |
|---|---|---|---|
| **Actual 0** | 5,666 | 246 | 81 |
| **Actual 1** | 340 | 3,003 | 15 |
| **Actual 2** | 62 | 9 | 6,462 |

Class 1 ("both fire and smoke") is the hardest to separate, most often confused with class 0 , since both classes contain fire and/or smoke. Class 2 ("neither") is classified almost perfectly.

For context, this model substantially outperforms an earlier 4-block CNN trained from scratch on the same data, which reached ~75% accuracy.

## Repo structure

```
.
├── fire_detection.ipynb   # data pipeline, model training (both phases), evaluation
├── EfficientNetB4_fd.keras # final-epoch trained model
└── README.md
```

## Requirements

```
tensorflow>=2.15
scikit-learn
numpy
pandas
matplotlib
seaborn
```

```bash
pip install tensorflow scikit-learn numpy pandas matplotlib seaborn
```

Training was originally run on Kaggle (Tesla P100 GPU). A GPU is strongly recommended — Phase 2 fine-tuning takes ~4 minutes/epoch on a P100.

## Usage

1. Download the [FASDD_CV](https://www.kaggle.com/datasets/yuulind/fasdd-cv-coco) dataset and update the `train`/`val` folder paths in the notebook (currently set to Kaggle's default `/kaggle/input/...` paths).
2. Run `fire_detection.ipynb` top to bottom to reproduce training.
3. To run inference with the trained model:

```python
import tensorflow as tf

model = tf.keras.models.load_model("EfficientNetB4_fd.keras")

img = tf.io.read_file("path/to/image.jpg")
img = tf.image.decode_jpeg(img, channels=3)
img = tf.image.resize(img, [300, 300])
img = tf.cast(img, tf.float32)
img = tf.expand_dims(img, axis=0)

pred = model.predict(img)
class_id = pred.argmax(axis=1)[0]
```

## Roadmap

- [ ] Real-time inference on a live camera feed
- [ ] Alerting pipeline for detected fire/smoke events
- [ ] Address class-1 confusion (e.g. class weighting, targeted augmentation)
- [ ] Model export to a lighter format (TFLite/ONNX) for edge deployment

## Acknowledgments

- Dataset: *FASDD: An Open-access 100,000+ image Fire and Smoke Detection Dataset for Deep Learning in Fire Detection*.
- Backbone: EfficientNetB4 , via `tf.keras.applications`.
