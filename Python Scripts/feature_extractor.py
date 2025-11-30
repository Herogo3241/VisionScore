import tensorflow as tf
keras = tf.keras
from keras import layers, models

base_model = keras.applications.MobileNetV2(
    include_top=False,
    weights='imagenet',
    pooling='avg',
    input_shape=(224,224,3)
)

inputs = layers.Input(shape=(224, 224, 3), name="image_input")

x = keras.applications.mobilenet_v2.preprocess_input(inputs)

x = base_model(x)

x = layers.Dense(64, activation='relu', name="embedding")(x)

model = models.Model(inputs, x)
model.summary()

model.save("feature_extractor.h5")



