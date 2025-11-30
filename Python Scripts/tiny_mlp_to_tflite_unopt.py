import tensorflow as tf

model = tf.keras.models.load_model("tiny_mlp.h5")

converter = tf.lite.TFLiteConverter.from_keras_model(model)
unopt_model = converter.convert()

open("music_model_unopt.tflite", "wb").write(unopt_model)