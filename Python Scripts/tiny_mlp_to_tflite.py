import tensorflow as tf

model = tf.keras.models.load_model("tiny_mlp.h5")


converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]  # int8/fp16 optimization
tflite_model = converter.convert()

with open("music_model.tflite", "wb") as f:
    f.write(tflite_model)

