import tensorflow as tf


model = tf.keras.models.load_model("feature_extractor.h5")


converter = tf.lite.TFLiteConverter.from_keras_model(model)


converter.optimizations = [tf.lite.Optimize.DEFAULT]


# 4. Convert the model
tflite_model = converter.convert()

# 5. Save .tflite
with open("feature_model.tflite", "wb") as f:
    f.write(tflite_model)

print("Saved feature_model_dynamic.tflite (Dynamic Range Optimized).")