import numpy as np
import tensorflow as tf
keras = tf.keras
from keras import layers, models

NUM_SAMPLES = 200000
FEATURE_DIM = 64



X = np.random.rand(NUM_SAMPLES, FEATURE_DIM).astype("float32")

#image parameters
brightness = X.mean(axis=1)
edge_strength = X[:, :8].mean(axis=1)
colorfulness = X[:, 8:16].std(axis=1)
texture = X[:, 16:32].mean(axis=1)


#music parameters
tempo = 60 + brightness * 100
mood = np.clip(colorfulness, 0, 1)
rhythm_complexity = np.clip(edge_strength, 0, 1)
percussion_level = np.clip(texture, 0, 1)
key_index = (X[:, 0] * 12).astype(np.int32)
is_minor = (X[:, 1] > 0.5).astype(np.float32)
melody_pattern = (X[:, 2] * 4).astype(np.int32)

Y = np.vstack([
    tempo,
    key_index,
    is_minor,
    mood,
    rhythm_complexity,
    melody_pattern,
    percussion_level
]).T.astype("float32")

#tiny mlp model
model = models.Sequential([
    layers.Input(shape=(FEATURE_DIM, )),
    layers.Dense(64, activation="relu"),
    layers.Dense(32, activation="relu"),
    layers.Dense(7, activation="linear")
])

model.compile(optimizer="adam", loss="mse")
model.summary()

#training model
model.fit(X, Y, epochs=20, batch_size=12)


model.save("tiny_mlp.h5")



