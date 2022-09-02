# Title: AnimToShapeKey
# Current Version: Alpha 1.0
# ///////////////////////////////////////////////////////////////////////////////
# LICENSE:
# MIT License

# Copyright (c) 2022 Miodrag Sejic aka DigitalN8m4r3
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# ///////////////////////////////////////////////////////////////////////////////
# Instructions:
# Step I:
# select the Object that contains the KeyFrame animation,
# shift select the Object, that is the receiver
# as in the Object that is going to receive the ShapeKeys from the Animation
# ------------------------------------------------------------------------------
# Step II:
# switch Workspace to Scripting, copy/paste this script, run the script

import bpy, re
# START - Blendshape Conversion: this transfers the animations from one object to the other as shapekeys
# START - Blink
bpy.ops.object.join_shapes() #Frame 1 eyeBlinkLeft
bpy.data.scenes['Scene'].frame_set(bpy.data.scenes['Scene'].frame_current + 1)
bpy.ops.object.join_shapes() #Frame 2 eyeBlinkRight
bpy.data.scenes['Scene'].frame_set(bpy.data.scenes['Scene'].frame_current + 1)
# END - Blink
# START - Viseme 
bpy.ops.object.join_shapes() #Frame 3 viseme_CH
bpy.data.scenes['Scene'].frame_set(bpy.data.scenes['Scene'].frame_current + 1)
bpy.ops.object.join_shapes() #Frame 4 viseme_DD
bpy.data.scenes['Scene'].frame_set(bpy.data.scenes['Scene'].frame_current + 1)
bpy.ops.object.join_shapes() #Frame 5 viseme_E
bpy.data.scenes['Scene'].frame_set(bpy.data.scenes['Scene'].frame_current + 1)
bpy.ops.object.join_shapes() #Frame 6 viseme_FF
bpy.data.scenes['Scene'].frame_set(bpy.data.scenes['Scene'].frame_current + 1)
bpy.ops.object.join_shapes() #Frame 7 viseme_I
bpy.data.scenes['Scene'].frame_set(bpy.data.scenes['Scene'].frame_current + 1)
bpy.ops.object.join_shapes() #Frame 8 viseme_O
bpy.data.scenes['Scene'].frame_set(bpy.data.scenes['Scene'].frame_current + 1)
bpy.ops.object.join_shapes() #Frame 9 viseme_PP
bpy.data.scenes['Scene'].frame_set(bpy.data.scenes['Scene'].frame_current + 1)
bpy.ops.object.join_shapes() #Frame 10 viseme_RR
bpy.data.scenes['Scene'].frame_set(bpy.data.scenes['Scene'].frame_current + 1)
bpy.ops.object.join_shapes() #Frame 11 viseme_SS
bpy.data.scenes['Scene'].frame_set(bpy.data.scenes['Scene'].frame_current + 1)
bpy.ops.object.join_shapes() #Frame 12 viseme_TH
bpy.data.scenes['Scene'].frame_set(bpy.data.scenes['Scene'].frame_current + 1)
bpy.ops.object.join_shapes() #Frame 13 viseme_U
bpy.data.scenes['Scene'].frame_set(bpy.data.scenes['Scene'].frame_current + 1)
bpy.ops.object.join_shapes() #Frame 14 viseme_aa
bpy.data.scenes['Scene'].frame_set(bpy.data.scenes['Scene'].frame_current + 1)
bpy.ops.object.join_shapes() #Frame 15 viseme_kk
bpy.data.scenes['Scene'].frame_set(bpy.data.scenes['Scene'].frame_current + 1)
bpy.ops.object.join_shapes() #Frame 16 viseme_nn
bpy.data.scenes['Scene'].frame_set(bpy.data.scenes['Scene'].frame_current + 1)
bpy.ops.object.join_shapes() #Frame 17 viseme_sil
bpy.data.scenes['Scene'].frame_set(bpy.data.scenes['Scene'].frame_current + 1)
# END - Viseme 
# END - Blendshape Conversion

# get the receiver Object
receiver = bpy.context.object

# get the blendshapes of the receiver Object
blendshapes = receiver.data.shape_keys.key_blocks

# ShapeID defines the names for the converted blendshapes
ShapeId = ['eyeBlinkLeft', 'eyeBlinkRight', 'viseme_CH', 'viseme_DD', 'viseme_E', 'viseme_FF', 'viseme_I', 'viseme_O', 'viseme_PP', 'viseme_RR', 'viseme_SS', 'viseme_TH', 'viseme_U', 'viseme_aa', 'viseme_kk', 'viseme_nn', 'viseme_sil']
# this loops through the blendshapes and if the blendshape is not called "Basis" it will rename the blendshape accordingly to the provided ShapeId
for index, key in enumerate(blendshapes):
    if key.name != "Basis":
        try: key.name = ShapeId[index -1]
        except: pass
# ///////////////////////////////////////////////////////////////////////////////
# ChangeLog:
# 29.08.2022 Alpha 1.0
# added Eye Blink and Viseme
# Do Note: this Script is going to receive Updates in the future
# ///////////////////////////////////////////////////////////////////////////////