import numpy as np
import tensorflow.lite as tflite

# Load models
mobilenet = tflite.Interpreter("feature_model.tflite")
mobilenet.allocate_tensors()

mlp = tflite.Interpreter("music_model.tflite")
mlp.allocate_tensors()

# Generate a dummy feature tensor
# (or you can use a real MobileNet output)
input_details = mobilenet.get_input_details()
output_details = mobilenet.get_output_details()

# If you have a real image inference done:
# feature_vector = real_output_from_mobilenet
# Otherwise simulate:
feature_vector = np.random.rand(1, 64).astype("float32")

# Run MLP
mlp_input = mlp.get_input_details()
mlp_output = mlp.get_output_details()

mlp.set_tensor(mlp_input[0]['index'], feature_vector)
mlp.invoke()
params = mlp.get_tensor(mlp_output[0]['index'])[0]

print("Predicted parameters:")
print("Tempo:", params[0])
print("Key index:", params[1])
print("Is minor:", params[2])
print("Mood:", params[3])
print("Rhythm complexity:", params[4])
print("Melody pattern:", params[5])
print("Percussion level:", params[6])
