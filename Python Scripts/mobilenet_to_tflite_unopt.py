import tensorflow as tf

# Load your Keras feature extractor
model = tf.keras.models.load_model("feature_extractor.h5")

# Convert WITHOUT any optimizations → float32 baseline
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_unopt = converter.convert()

with open("feature_model_unopt.tflite", "wb") as f:
    f.write(tflite_unopt)

print("Saved feature_model_unopt.tflite (float32 baseline).")
