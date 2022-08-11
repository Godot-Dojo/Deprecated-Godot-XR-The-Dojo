# Godot XR Avatar

<img src="./XRBody-1.gif" alt="Keyboard GIF" width="568" height="320">

This repository contains a demo scene for having a full body player avatar using Godot's XR Plugin and XR Tools plugin.

This repo's code is based heavily from / derived from the work of SYBIOTE (https://github.com/SYBIOTE) based on an unpublished project for VR avatars that he graciously shared.

SYBIOTE's original code was made to be used with functions and code from the Godot Oculus Quest Toolkit, developed by NeoSpark314 (https://github.com/NeoSpark314/godot_oculus_quest_toolkit), and so some of the functions of the toolkit were translated and used in this project.

This repo translates various code from reliance on the Oculus Quest Toolkit and OVR plugins to the newer OpenXR asset and XR Tools and then adds code to account for finger positioning.

You can find the latest version of the Godot OpenXR asset at: https://github.com/GodotVR/godot_openxr and XR Tools at https://github.com/GodotVR/godot-xr-tools. 

In further modifying the SYBIOTE code, inspiration was taken from GoatChurchPrime's work in https://github.com/goatchurchprime/OQ_Avatar_Mapping/


Additional thanks and credits go out to teddybear082 (https://github.com/teddybear082) who made it work with Godot's XR Plugin and much more and last but not least a special thank you to (https://github.com/Malcolmnixon), who fixed the remaining issues, without this additional help, this project would not be here.

The aim of this code is to be as modular/drag and drop as humanly possible while balancing the need for devs to likely adjust certain parameters.

Therefore, work, perhaps substantial work, is still required to enable this avatar code if you want to do so with your own avatar. 

READ THE INSTRUCTIONS BELOW.

## Versions

This is in an beta state, it is working but there are issues to be expected.

## How to Use

The demo scene is all set to use as is, just unzip the directory, run the project.godot in Godot 3.5 and hit play, and everything should work.

If you want to use in your own spearate project, follow these steps (work in progress, testing ongoing):

Install the OpenXR and XR Tools plugins as directed on their respective sites and be sure to activate them.

Setup your XR rig as you see fit.

Add your avatar character as a child of your ARVROrigin node (by default, this will be called "FPController" with the OpenXR / XR Tools assets)

At the root of your avatar character, which should be a spatial node, attach the avatargodot.gd script found in scenes/vr_body to the spatial node.

Follow the steps indicated in the top comments of the avatar.gd script to finish setting up your character, copied and pasted here:

(1) add an AnimationTree node as a child of the avatar root Spatial with proper animation blends pointing to the character AnimationPlayer

(2) add a SkeletonIK node as a child of the avatar root Spatial called "SkeletonIKL" set to Root Bone of Left Shoulder and Tip Bone set to Left Hand, Use Magnet, Magnet.X = 10, Interpolation set to 1  

(3) add a SkeletonIK node as a child of the avatar root Spatial called "SkeletonIKR" set to Root Bone of Right Shoulder and Tip Bone set to Right Hand, Use Magnet, Magnet.X = -10, Interpolation set to 1 

(4) add a SkeletonIK node as a child of the avatar root Spatial called "SkeletonIKLegL" set to LeftUpLeg and Tip Bone set to LeftFoot, Use Magnet, Magnet (.2,0,1), Interpolation set to 1; 

(5) adda a SkeletonIK node as a child of the avatar root Spatial called "SkeletonIKLegR"  set to RightUpLeg and Tip Bone set to RightFoot, Use Magnet, Magnet (-.2,0,1), Interpolation set to 1; 

(6) add a bone attachment node as a child of the avatar root Spatial called "character_height" set to top of avatar head/Head_Top_End

(7) add a bone attachment node as a child of the avatar root Spatial called "right_foot" set to RightFoot bone of the avatar; 

(8) add a bone attachment node as a child of the avatar root Spatial called "left_foot" set to LeftFoot bone of the avatar.

Then there should be no errors in the script and you should now have export variables appear on the avatar root Spatial that has the avatar.gd script.

Be sure to choose your node paths for your ARVROrigin, ARVRCamera, left controller, right controller, and left and right hand nodes and select which controller you are using for direct movement.

If you want to hide the head node, be sure to select the nodes that pertain to the head/face in your avatar in the export array indicated for that purpose (head mesh nodes) and then choose the box to hide the head mesh.

You can choose whether to hide the heads or hand meshes as export variables.

### Other tips

The avatar legs are controlled by animations.  You need to have animations for walk forward, backward, left strafe and right strafe for your avatar if you want those to work.  For the indcluded avatar those are all set up already.

Then you need to set up the AnimationTree child of the avatar as you see in the demo scene - with the idle animation as the main AnimationRootNode and then a BlendSpace2d that has the animations assigned to the four points of the diamond of the blendspace.  The avatar code then blends these animations depending on what direction the player is moving.  Check the included avatar for examples.  You can then also enable hand poses by adding additional nodes to the AnimationTree if you have a hand pose animation set up for your avatar.

## Video Tutorials

Tutorials forthcoming.

Licensing
---------
The CODE in this repository is licensed under the MIT license, however everything else including the Avatar model is under the CC0 Public Domain License.

About this repository
---------------------
This repository was created by and is maintained by DigitalN8m4r3 and teddybear082
