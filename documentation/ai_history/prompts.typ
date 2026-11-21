// Auto-generated from Gemini-_52.json
#let prompts = (
  [
_rendered\_image\.gd akkori változata_ \
Hi\. I am making a godot addon that integrates gaussian splatting into the editor\/games, as nodes that can be moved\. I have an autoload singleton with a fullscreen quad where the drawing happens\. This works fine when running the game\. However, I am not sure how it would work in the editor, which would be pretty cool\. This way people could see their splat objects also in the editor\. Now I am getting a bunch of errors from the autoload singleton, which would suggest that it is actually loaded in the editor (it is a \@tool script, however I was not sure if that also is enough for autoload singletons to start during edited scenes, it looks like it is)\.

The errors point to the following problem: \
splat\_filenames is empty on line 34, meaning the initialization of the rest of the scene probably happens after that is  called\. It is probably indeed true, since if I close the main demo scene, the errrors keep repeating, suggesting that the autoload tools are loaded before everything, and keep running, even if there is no 3d scene open\.

So my guess for a fix is to make dynamically loading\/unloading splat files possible, and that would possibly solve this as well\. My question is what do you think of all of this, and also do you know if the autoload tool is only the script running, or the attached MeshInstance3D will also be available in the editor in case a 3d scene is opened, rendering the splat objects hopefully in the right place, as they do during running the scene?
  ],
  [
~Tried capturing more timestamps than the configured maximum (256)\. You can increase this limit in the project settings under \'Debug\/Settings\' called \'Max Timestamp Query Elements\'\. \
?
  ],
  [
I want to change these to basic debug prints, what is the recommended function?

func print\_debug\_info() \-\> void: \
~~~~var fps :\= Engine\.get\_frames\_per\_second() \
~~~~ImGui\.Text(\'Drag and drop \.ply files on the window to load!\') \
~~~~ \
~~~~ImGui\.SeparatorText(\'GaussianSplatting\') \
~~~~ImGui\.Text(\'FPS:             %d (%s)\' % \[fps, \'%\.2fms\' % (1e3 \/ fps)\]) \
~~~~ImGui\.Text(\'Loaded File:     %s\' % \[\'(loading\.\.\.)\' if rasterizer and not rasterizer\.is\_loaded else loaded\_file\]) \
~~~~ImGui\.Text(\'VRAM Used:       %s\' % video\_memory\_used) \
~~~~ImGui\.Text(\'Rendered Splats: %s\' % num\_rendered\_splats)
  ],
  [
how do I call this function print\_debug\_info() every 1 second without the timer node
  ],
  [
_rendered\_image\.gd akkori változata_ \
_splat\_mesh\.gd akkori változata_ \
Okay\. Now I want to change the system of rendered\_image collecting the splat\_mesh\-es so that the splat\_mesh\-es register themselves instead\. I am attaching the files\. Please rewrite both so that that happens\. Make sure to: \
\- add and remove the splat mesh in case of loading \+ exiting the tree \
\- same for toggling visibility (inside editor as well as in\-game) \
if you need to, call the whole init\_rasterizer for every update (also probably the cleanup one beforehand) \
think about other possibilities when the splatmesh needs to ask visibility change from the renderer\. \
You don\'t have to think about displaying the meshinstance in the editor, it looked like it will just work\. \
Please write an exhaustive list of the changed functions, so that I don\'t have to use a diff util to see what changed\.
  ],
  [
Nice, it works well in the editor\. However, it crashes when starting the game actually, because 

~~~~rasterizer \= GaussianSplattingRasterizer\.new(ply\_file, viewport\.size, render\_texture, camera)

here viewport is nil, idk why\.

One more question, why is 

~~~~var renderer \= get\_node\_or\_null(\"\/root\/RenderedImage\") \
~~~~if renderer and renderer\.has\_method(\"register\_splat\"): \
~~~~~~~~renderer\.register\_splat(self) \
better compared to just  \
~~~~GsplatRenderedImage\.register\_splat(self) \
which I wrote in the end? the 2nd one is much more readable, and I want to explicitly get an error if the singleton(or the function) is not available, since that would be the main goal
  ],
  [
should we not also defer the init in case the viewport is not found?
  ],
  [
_gaussian\_splatting\_rasterizer\.gd akkori változata_ \
nice, but there is a small error, because the 2 objects simulatneously request the reload (so the 2nd reload is triggered before the 1st one finished)\. Can we somehow defer the reloads by 1 frame and wait for every simultaneous reload request before starting the actual reload? Or just make sure this function doesn\'t throw an error in case we continuously spam it?

func cleanup\_gpu(): \
~~~~should\_terminate\_thread\[0\] \= true \
~~~~load\_thread\.wait\_to\_finish() \
~~~~if context: context\.free() \
~~~~if render\_texture: render\_texture\.texture\_rd\_rid \= RID()

cuz it says for this line (    load\_thread\.wait\_to\_finish()) 

E 0:01:43:0569   gaussian\_splatting\_rasterizer\.gd:120 \@ cleanup\_gpu(): Thread must have been started to wait for its completion\. \
~~\<C\+\+ Error\>    Condition \"!is\_started()\" is true\. Returning: Variant() \
~~\<C\+\+ Source\>   core\/core\_bind\.cpp:1318 \@ wait\_to\_finish() \
~~\<Stack Trace\>  gaussian\_splatting\_rasterizer\.gd:120 \@ cleanup\_gpu() \
~~~~~~~~~~~~~~~~~rendered\_image\.gd:32 \@ \_update\_rasterizer\_state() \
~~~~~~~~~~~~~~~~~rendered\_image\.gd:20 \@ unregister\_splat() \
~~~~~~~~~~~~~~~~~splat\_mesh\.gd:35 \@ \_unregister() \
~~~~~~~~~~~~~~~~~splat\_mesh\.gd:29 \@ \_update\_registration()
  ],
  [
okay, this sounds good\. One more observation, dont you think \_enter\_tree() and \_exit\_tree() are too early\/late for the splat init, shouldn\'t they be in \_ready() (and the corresponding exit one)?

\@tool \
class\_name SplatMesh extends Node3D

\@export var ply\_file: String : \
~~~~set(value): \
~~~~~~~~if ply\_file !\= value: \
~~~~~~~~~~~~\# Unregister the old file first \
~~~~~~~~~~~~\_unregister() \
~~~~~~~~~~~~ply\_file \= value \
~~~~~~~~~~~~\# Register with the new file \
~~~~~~~~~~~~\_update\_registration()

func \_enter\_tree() \-\> void: \
~~~~\# Listen for visibility toggles (the eye icon in the editor, or hide() in\-game) \
~~~~if not visibility\_changed\.is\_connected(\_update\_registration): \
~~~~~~~~visibility\_changed\.connect(\_update\_registration) \
~~~~\_update\_registration()

func \_exit\_tree() \-\> void: \
~~~~if visibility\_changed\.is\_connected(\_update\_registration): \
~~~~~~~~visibility\_changed\.disconnect(\_update\_registration) \
~~~~\_unregister()

func \_update\_registration() \-\> void: \
~~~~\# is\_visible\_in\_tree() checks this node AND all parent visibilities \
~~~~if is\_inside\_tree() and is\_visible\_in\_tree(): \
~~~~~~~~\_register() \
~~~~else: \
~~~~~~~~\_unregister()

func \_register() \-\> void: \
~~~~GsplatRenderedImage\.register\_splat(self)

func \_unregister() \-\> void: \
~~~~GsplatRenderedImage\.unregister\_splat(self)
  ],
  [
nice, that is good\. It works alright\. \
Now in case the editor is running long enough, I am getting batches of 4 of these errors: \
Tried capturing more timestamps than the configured maximum (256)\. You can increase this limit in the project settings under \'Debug\/Settings\' called \'Max Timestamp Query Elements\'\. \
probably because of the rasterizer\'s capture\_timestamp calls\. I only keep getting them if there is a 3d scene open, and I\'m not moving in it (so i guess when it doesn\'t reload) \
So I guess it fills some kind of buffer which overflows\. what should I do about them? I don\'t even get the correct output from them on the console, there are no stage timings in the debug print, not even in the original imgui version I based this on\.
  ],
  [
Nice, that is good\. the next thing we should do is the following: \
in case there are 0 splat objects, the fsquad is white somtimes, instead of transparent\. How do we make it transparent?
  ],
  [
_splat\_mesh\.gd akkori változata_ \
thats good! now I want to make it so that the splat mesh only calls for modification on file path change in case the file actually exists, not for every single letter change in the editor\.
  ],
  [
nice! my next question is that \.ply files are not showing up in the editor, how do I make them first class citizens, e\.g\. showing up in the filesystem in the editor, maybe make them resources so that they can be dragged instead of just having to type the path string, maybe have import options for them down the line, etc\. is it worth it? Also, this is needed for them to be able to be bundled for exported builds, right?
  ],
  [
do you think it would be worth it for the splatmeshes to also push their 3d transforms instead of the fsquad script to collect it, or it doesn\'t really matter?
  ],
  [
_ply\_file\.gd akkori változata_ \
a few more questions regarding the plyfile resource thing\. How does it work if I want to add support for the gltf splat format later, do I make a new importer for that as well? how do I name it consistently e\.g\.? and how does this current one work? this is the original ply\_file\.gd, I dont think I need to modify it since it already inherits from Resource and has a class\_name\. I\'ll have to create an OO hierarchy if I want to add gltfSplatFile tho, am I right?
  ],
  [
but does this also mean that when I export the game, it will make the binary much bigger, since e\.g\. the once compressed gltf file will be decompressed on exort?
  ],
  [
nice\. Please create the 2 new scripts for me based on the ply\_file\.gd I attached above\. For the gaussian\_splat\_data\.gd (which was ply\_file\.gd) please only list the changes\. For the ply\_importer\.gd create the whole file\.
  ],
  [
_splat\_mesh\.gd akkori változata_ \
nice, its starting to get shape\. Now please reshape this file\. And also this part of the code, that is in the autoload meshinstance3d for rendering (rendered\_image\.gd):

var splat\_meshes : Array\[SplatMesh\] \= \[\]

var rasterizer\_update\_queued :\= false

func register\_splat(splat: SplatMesh) \-\> void: \
~~~~if splat not in splat\_meshes: \
~~~~~~~~splat\_meshes\.append(splat) \
~~~~~~~~assert(len(splat\_meshes) \<\= GaussianSplattingRasterizer\.MAX\_OBJECT\_COUNT) \
~~~~~~~~queue\_rasterizer\_update()

func unregister\_splat(splat: SplatMesh) \-\> void: \
~~~~if splat in splat\_meshes: \
~~~~~~~~splat\_meshes\.erase(splat) \
~~~~~~~~queue\_rasterizer\_update()

func queue\_rasterizer\_update() \-\> void: \
~~~~\# If an update is already scheduled for this frame, ignore the request \
~~~~if not rasterizer\_update\_queued: \
~~~~~~~~rasterizer\_update\_queued \= true \
~~~~~~~~call\_deferred(\"update\_rasterizer\_state\")

func update\_rasterizer\_state() \-\> void: \
~~~~rasterizer\_update\_queued \= false \
~~~~var splat\_filenames :\= \[\] \
~~~~for m in splat\_meshes: \
~~~~~~~~if m\.ply\_file and not m\.ply\_file\.is\_empty(): \
~~~~~~~~~~~~splat\_filenames\.append(m\.ply\_file) \
~~~~ \
~~~~if splat\_filenames\.size() \> 0: \
~~~~~~~~visible \= true \
~~~~~~~~init\_rasterizer(splat\_filenames) \
~~~~else: \
~~~~~~~~visible \= false \
~~~~~~~~if rasterizer: \
~~~~~~~~~~~~RenderingServer\.call\_on\_render\_thread(rasterizer\.cleanup\_gpu) \
~~~~~~~~~~~~rasterizer \= null

\.\.\.

func init\_rasterizer(ply\_file\_paths : Array) \-\> void: \
~~~~\# Need to use get\_singleton because of https:\/\/github\.com\/godotengine\/godot\/issues\/91713 \
~~~~var current\_viewport \= Engine\.get\_singleton(\'EditorInterface\')\.get\_editor\_viewport\_3d(0) if Engine\.is\_editor\_hint() else get\_viewport()

~~~~var current\_camera \= current\_viewport\.get\_camera\_3d() \
~~~~assert(current\_camera)

~~~~~~~~\# TODO what if we create multiple viewports??? \
~~~~if not current\_viewport\.size\_changed\.is\_connected(reset\_render\_texture): \
~~~~~~~~current\_viewport\.size\_changed\.connect(reset\_render\_texture) \
~~~~ \
~~~~if rasterizer: RenderingServer\.call\_on\_render\_thread(rasterizer\.cleanup\_gpu) \
~~~~ \
~~~~var ply\_file \= GaussianSplatData\.new(ply\_file\_paths\[0\]) \
~~~~for file in ply\_file\_paths\.slice(1): \
~~~~~~~~if file\.ends\_with(\'\.ply\'): \
~~~~~~~~~~~~var next\_ply\_file \= GaussianSplatData\.new(file) \
~~~~~~~~~~~~ply\_file \= GaussianSplatData\.merge(ply\_file, next\_ply\_file) \
~~~~ \
~~~~var render\_texture :\= Texture2DRD\.new() \
~~~~rasterizer \= GaussianSplattingRasterizer\.new(ply\_file, current\_viewport\.size, render\_texture, current\_camera) \
~~~~get\_surface\_override\_material(0)\.set\_shader\_parameter(\'render\_texture\', render\_texture)
  ],
  [
nice, all that is good\. Now please suggest me the names that make the most sense\. So you know what MeshInstance3D and mesh resources mean in Godot I guess\. I want to create something similar for these, and I dont think this GaussianSplatData and SplatMesh really convey what they really are\. Please suggest names\. My thoughts: I don\'t like names that are very long\. \
So I\'d think: GSplatInstance3D for the node (to keep the \+3D naming convention), with a data field that is of type GSplatData \
GSplat doesn\'t look very good, but gaussian is just too long in my opinion, and everyone who reads it not for the first time is tired of reading the whole name, while the important information afterwards is shadowed bc most of the time the textfield isnt that big, and the important stuff actually get covered\. sry that was a bit long\. My other problem is that this is not a single Gsplat \"instance\" per se, it is an instance of a model made out of gsplats\. But how do I make it short and snappy?
  ],
  [
good\. In the end they became SplatCloud3D and SplatCloudData\. How do I create a simple icon for them? is it easy? so that they have a special icon in the FileSystem of the editor, and the scene tree
  ],
  [
you don\'t have to suggest this debug draw thing, the default node3d gizmo will be just fine, in case the ply file is not there, or fails to load\. \
Otherwise thank you, this is straight\-forward\. Please try to generate two nice SVG files for me for the data and the node3d\. Here are 2 sample SVG files from the godot source\.

MeshInstance3D: \
\<svg xmlns\=\"http:\/\/www\.w3\.org\/2000\/svg\" width\=\"16\" height\=\"16\"\>\<path fill\=\"\#fc7f7f\" d\=\"M4\.73 2A2 2 0 1 0 2 4\.73v6\.541A2 2 0 1 0 4\.73 14h6\.541A2 2 0 1 0 14 11\.27V4\.729A2 2 0 1 0 11\.27 2Zm\.683 2h5\.857a2 2 0 0 0 \.729\.73v5\.856L5\.412 4zM3\.999 5\.414 10\.584 12H4\.727a2 2 0 0 0\-\.729\-\.73V5\.414z\"\/\>\<\/svg\>

ArrayMesh: \
\<svg xmlns\=\"http:\/\/www\.w3\.org\/2000\/svg\" width\=\"16\" height\=\"16\"\>\<path fill\=\"\#ffca5f\" d\=\"M3 1a2 2 0 0 0 0 4 2 2 0 0 0 0\-4zm10 0a2 2 0 0 0 0 4 2 2 0 0 0 0\-4zm\-2 7v3H8v2h3v3h2v\-3h3v\-2h\-3V8zm\-8 3a2 2 0 0 0 0 4 2 2 0 0 0 0\-4z\"\/\>\<\/svg\>
  ],
  [
Nice, it looked pretty good\. However, I updated the editor version to 4\.6 (and had to copy a fix, but that is irrelevant now) and the icons are now a bit off in color compared to the other icons\. A bit paler\. Idk what happened, since previously they were fine, and also the color code is exactly the same (I copied the files I pasted from the master branch, which is the most recent, and also the 4\.6 branch had the same colorcodes)\. I suspect they did some tomfoolery because of the new theme, and they didn\'t want to update all the icons, and applied some script to them instead\. And it is not  applied to our icons\. Should I look into the svg import options? or any suggestions? can you find something online e\.g\.?
  ],
  [
yup thats fine, I\'ll wait, I love bugs that solve themselves with waiting xddd
  ],
  [
actually, that is only part of the truth, because I looked at the issue you found, and they actually pointed to 2 import settings which solve the problem: \
https:\/\/docs\.godotengine\.org\/en\/stable\/tutorials\/plugins\/editor\/making\_plugins\.html\#a\-custom\-node
  ],
  [
nice\. But smthg else broke too, the \.ply files in the FileSystem dock are now basic A4 paper icons, even though otherwise the resource icon works well\. IIrc it worked fine in v4\.3\. Can you find something related to this?
  ],
  [
nice idea, but it doesn\'t look like it changed anything\. I guess they it must be reimported, then I got the following errors:

ERROR: No loader found for resource: res:\/\/\.godot\/imported\/teddy\.ply\-06134c725915ab499eba1b4c10403975\.res (expected type: SplatCloudData) \
~~ERROR: Failed loading resource: res:\/\/models\/teddy\.ply\. \
~~ERROR: No loader found for resource: res:\/\/\.godot\/imported\/toyota\_tire\.ply\-2230ae51b46760a8d1bd41555efafd08\.res (expected type: SplatCloudData) \
~~ERROR: Failed loading resource: res:\/\/models\/toyota\_tire\.ply\. \
~~ERROR: No loader found for resource: res:\/\/\.godot\/imported\/toyota\_wotire\.ply\-03f30ac771104a53a7dce9160d39c20b\.res (expected type: SplatCloudData) \
~~ERROR: Failed loading resource: res:\/\/models\/toyota\_wotire\.ply\.
  ],
  [
Is there an issue for this i can read? or did people not even notice it?
  ],
  [
nice! okay, thats fine\. I shouldn\'t be worrying too much about small icons and mismatching colors until we solve a bigass memoryleak somewhere, total amd incompatibility or the editor freezing \/ being much more sluggish when working with a splatted scene xd, but that is for next time, cya\.
  ],
  [
_gsplat\_boundaries\.glsl akkori változata_ \
_gsplat\_projection\.glsl akkori változata_ \
_gsplat\_render\.glsl akkori változata_ \
_main\.gdshader akkori változata_ \
_radix\_sort\_downsweep\.glsl akkori változata_ \
_radix\_sort\_spine\.glsl akkori változata_ \
_radix\_sort\_upsweep\.glsl akkori változata_ \
Hi\. Let\'s look at the AMD driver thing\. What looks perfectly normal on an NVIDIA gpu, looks like this on AMD (linux and windows): \
The parellel units (little squares)\'s edges are sometimes visible, and if I see well, always there is only one splat in every parellel unit\. And often it is fully transparent, even though there should be something there\. My theory is that the translucent \/ alpha blending thing is not working: hence if there is a splat at the parellel processing unit visible, it is fully opaque, and if the splat that tries to be there and be opaque is further away, there will be nothing there\. \
So there is something about the alpha blending\. \
I attach all the glsl code of the project\. Please look at it, and also look it up on the internet, and tell me what you find\.
  ],
  [
thank you, it was something to try at least\. But these didn\'t change anything sadly\. Try to poke around the combination logic in the parellel batches, it does look like it uses only one splat\'s info instead of combining them all\.
  ],
  [
Hi, I have some stability issues, as well as crashes,  \
and also stutters when I start moving the editor window\. What do you suggest to do, could this be because of the fsquad rendering method, what else can I look into?
  ],
  [
yeah, I meant moving the main editor 3D view, but this gpu command flooding might be it!

2nd, very big thing, is that recently a chinese guy published a project very similar to this: https:\/\/github\.com\/ReconWorldLab\/godot\-gaussian\-splatting\/tree\/main

so I don\'t feel like reimplementing the wheel, and I\'ll probably merge the 2 projects, and continue from a common codebase\.

He also does use the compositoreffect thing, and curiously his editor is very responsive, doesn\'t look like it has memory leak, doesn\'t crash, and is looking pretty good all in all\. This call\_on\_render\_thread, the whole resize fixme memory leak, and the whole thing can be avoided if we use the compositoreffect I think, and the alpha blending will be easier maybe too\.
  ],
  [
_gaussian\_splatting\_rasterizer\.gd akkori változata_ \
_render\_context\.gd akkori változata_ \
_rendered\_image\.gd akkori változata_ \
_GaussianRenderManager\.gd akkori változata_ \
_RenderingContext\.gd akkori változata_ \
_postprocess\.gd akkori változata_ \
Here are my files, and his files (mine are the first 3, snake\_case ones, and his are the last 3, PascalCase ones \+ postprocess)\. Please rewrite my three files to use his implementation for the compositoreffect, while I need to change as little as possible in the remaining code\.
  ],
  [
_post\.glsl akkori változata_ \
okay, I get that we could modify a lot of stuff to improve them, but right now I just want a quick and dirty way of testing if moving to the compositoreffect actually fixes the instabilities and the memory problems\. So (idk how possible this is) I just want to replace the contents of my 3 attached files (delete rendered\_image and add a postprocess file), while keeping the exact same shaders, ply loading, transform uploading and splat merging\. As a bonus, here is his postprocess shader, which I\'d like to yoink with minimal modifications if possible\. How feasible is this?
  ],
  [
_splat\_cloud\_3d\.gd akkori változata_ \
this is my current file, please write me the splat mesh modifications for this too
  ],
  [
ERROR: res:\/\/addons\/gsplat\-nodes\/postprocess\.gd:78 \- Parse Error: Cannot infer the type of \"size\" variable because the value doesn\'t have a set type\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/postprocess\.gd:100 \- Parse Error: Cannot infer the type of \"scene\_tex\" variable because the value doesn\'t have a set type\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/postprocess\.gd:101 \- Parse Error: Cannot infer the type of \"scene\_depth\_tex\" variable because the value doesn\'t have a set type\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/scripts\/splat\_cloud\_3d\.gd:0 \- Compile Error: Failed to compile depended scripts\. \
~~ERROR: modules\/gdscript\/gdscript\.cpp:2907 \- Failed to load script \"res:\/\/addons\/gsplat\-nodes\/scripts\/splat\_cloud\_3d\.gd\" with error \"Compilation failed\"\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/scripts\/splat\_cloud\_3d\.gd:53 \- Invalid call\. Nonexistent function \'unregister\_splat\' in base \'GDScript\'\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/scripts\/splat\_cloud\_3d\.gd:53 \- Invalid call\. Nonexistent function \'unregister\_splat\' in base \'GDScript\'\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/scripts\/splat\_cloud\_3d\.gd:53 \- Invalid call\. Nonexistent function \'unregister\_splat\' in base \'GDScript\'\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/scripts\/splat\_cloud\_3d\.gd:53 \- Invalid call\. Nonexistent function \'unregister\_splat\' in base \'GDScript\'\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/scripts\/splat\_cloud\_3d\.gd:48 \- Invalid access to property or key \'splat\_transforms\' on a base object of type \'GDScript\'\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/scripts\/splat\_cloud\_3d\.gd:48 \- Invalid access to property or key \'splat\_transforms\' on a base object of type \'GDScript\'\.
  ],
  [
okayy, it is surprisingly good in the editor, in the main game it throws these errors:

E 0:00:01:997   GaussianSplattingRasterizer\.update\_camera\_matrices: Cannot call method \'get\_camera\_transform\' on a null value\. \
~~\<GDScript Source\>gaussian\_splatting\_rasterizer\.gd:180 \@ GaussianSplattingRasterizer\.update\_camera\_matrices() \
~~\<Stack Trace\> gaussian\_splatting\_rasterizer\.gd:180 \@ update\_camera\_matrices() \
~~~~~~~~~~~~~~~~postprocess\.gd:92 \@ \_render\_callback() \
~~~~~~~~~~~~~~~~gaussian\_splatting\_rasterizer\.gd:180 \@ update\_camera\_matrices() \
~~~~~~~~~~~~~~~~postprocess\.gd:92 \@ \_render\_callback() \
~~~~~~~~~~~~~~~~gaussian\_splatting\_rasterizer\.gd:180 \@ update\_camera\_matrices() \
~~~~~~~~~~~~~~~~postprocess\.gd:92 \@ \_render\_callback() \
~~~~~~~~~~~~~~~~gaussian\_splatting\_rasterizer\.gd:180 \@ update\_camera\_matrices() \
~~~~~~~~~~~~~~~~postprocess\.gd:92 \@ \_render\_callback() \
~~~~~~~~~~~~~~~~gaussian\_splatting\_rasterizer\.gd:180 \@ update\_camera\_matrices() \
~~~~~~~~~~~~~~~~postprocess\.gd:92 \@ \_render\_callback() \
~~~~~~~~~~~~~~~~gaussian\_splatting\_rasterizer\.gd:180 \@ update\_camera\_matrices() \
~~~~~~~~~~~~~~~~postprocess\.gd:92 \@ \_render\_callback() \
~~~~~~~~~~~~~~~~gaussian\_splatting\_rasterizer\.gd:180 \@ update\_camera\_matrices() \
~~~~~~~~~~~~~~~~postprocess\.gd:92 \@ \_render\_callback() \
~~~~~~~~~~~~~~~~gaussian\_splatting\_rasterizer\.gd:180 \@ update\_camera\_matrices() \
~~~~~~~~~~~~~~~~postprocess\.gd:92 \@ \_render\_callback() \
~~~~~~~~~~~~~~~~gaussian\_splatting\_rasterizer\.gd:180 \@ update\_camera\_matrices() \
~~~~~~~~~~~~~~~~postprocess\.gd:92 \@ \_render\_callback() \
~~~~~~~~~~~~~~~~gaussian\_splatting\_rasterizer\.gd:180 \@ update\_camera\_matrices() \
~~~~~~~~~~~~~~~~postprocess\.gd:92 \@ \_render\_callback()
  ],
  [
ohh\. hmmm\. Can you look at how we solved this previously? I think this shouldn\'t be a new problem, we had something in the previous files too
  ],
  [
_0001\-quick\-and\-dirty\-prototype\-to\-test\-CompositorEffect\-b\.patch akkori változata_ \
now please read these changes carefully, and explain every difference you find between the previous and the current state\. Also, please explain the new code while putting the old code next to it, that did the similar thing previously\. I know it is not easy, since we changed the main mechanic, but still, the core parts and manipulations we need to do stayed the same\. So please think about it for a long time, and then explain\. Also tell me any potential problems you find\.
  ],
  [
okay, thank you, I\'ll keep these in mind\. But right now the depth blending doesn\'t work as expected, always the gsplats are on top\. Please revise the changes, because previously this worked fine\.
  ],
  [
_gsplat\_boundaries\.glsl akkori változata_ \
_gsplat\_boundaries\.glsl\.patch akkori változata_ \
yup, still no luck\. Anyway, the one that the chinese guy made works, and I want to diff my code against his anyway, so lets get started on that one\. That will also make the alpha blending work well\. lets start with this file: \
The file is mine, and the patch file is compared with his
  ],
  [
_gsplat\_projection\.glsl akkori változata_ \
_gsplat\_render\.glsl\.patch akkori változata_ \
okay, sounds convincing! Next:
  ],
  [
_gsplat\_projection\.glsl akkori változata_ \
_gsplat\_projection\.glsl\.patch akkori változata_ \
no, sorry, wrong files \
I meant these first
  ],
  [
is there any modification from my file I should keep? (lets imagine the other parts of the code can interoperate with both versions)
  ],
  [
Okay, so I have a big theory for how we should go about the merge\. Since the chinese guy put much more effort into it, his code is much more polished, and first I wanted to go through the changes, and understand them, but tbf now I don\'t really want to xd\. Both of us started from the same starter project (2retr0 or smth was the name of the guy), and I didn\'t really care about the parts of that code I didn\'t want to modify there, either\. So instead I want to go through my project, identify any major features that are not present in his version (I mostly think that is visibility changes runtime only, that is the only thing that worked in mine, albeight very hackily, and doesn\'t work in his; and integrated icons for object types), and implement them there\. For the small changes, I think he actually went through my code, and implemented some stuff, e\.g\. something with a transform covariance, it was from my code he committed, and also a fix for amd hardware I suggested\. He also created better importers for multiple formats, which I may also want to extend for gltf\. But for that I also think that his exporter architecture would be better\. So now I think I will do a big ctrlc ctrlv xddd
  ],
  [
_gaussian\_splat\_node\.gd akkori változata_ \
_gaussian\_scene\_registry\.gd akkori változata_ \
_gaussian\_gpu\_state\_cache\.gd akkori változata_ \
_gaussian\_render\_manager\.gd akkori változata_ \
_gaussian\_renderer\.gd akkori változata_ \
_gaussian\_rendering\_device\_context\.gd akkori változata_ \
_gsplat\_boundaries\.glsl akkori változata_ \
_gsplat\_projection\.glsl akkori változata_ \
_gsplat\_render\.glsl akkori változata_ \
okay, I just added the editor icons back, that went smoothly\. Now let\'s get to the visibility changes\. I am attaching all the relevant source files\. I want you to analyze these files carefully, and tell me, which ones are more relevant, which one is doing what, and where I should modify them for \
1) instant visibility changes\. Meaning I don\'t want to re\-upload everything to the gpu when one visibility changes, I just want to temporarily reject the splats that are currently invisible\. If there is a splat that is invisible in the scene when I start the game, I still want its data to be uploaded, in case it gets visible, it should appear instantly\. \
2) I want you to analyze how they solve uploading arbitrary amounts of splat \"meshes\" onto the gpu, while still providing necessary transforms for them, and also how they are matching the transforms to the splats\. I want you to analyze how we could go about adding instancing: having e\.g\. 2 separate instances and matrices for the one splatcloud, and showing both of them separately\. \
how would we go about adding these? How much code would we need to modify? do we need multiple passes for instancing?
  ],
  [
sounds good! Visibility change was easy to get working luckily, so let\'s move onto the instancing\. Please write me a detailed change list we need to do to get it working\.
  ],
  [
where is the line where I tell the GPU how many times I need to run the main() of the shader ? do we need to modify that?
  ],
  [
I added these changes, and it works pretty fine, but surprisingly I didn\'t save a single byte of VRAM\. How is this possible?
  ],
  [
hi again, it has been a while\. We did manage to get the instancing working, and the PR was also accepted\. Now it is time to move onto relightable ply\/gs files\/meshes\. I want the following: \
Import a gaussian splat as usual (it is fine if we first require specific ply files) \
render it, potentially with pbr \
I have found some stuff, but please look into it online carefully, to find every possible software\/documentation\/project in the topic, before diving into one\. Also list the potential problems that could arise\.
  ],
  [
okay, that doesn\'t sound that bad\. I have also done some research, and managed to set up mesh2splat (EA)\. I did convert the blender monkey, and I can already import it and display it inside the editor\/game, it is just not relighted at all\. I think I will go on the path of displaying gaussian splats converted from meshes, since it makes testing easier\. (and of course if someone wants to display real\-world pbr gs files, they will be able to do that as well with minor modifications, if I implemented the rendering\/import)\. Here is the header:

ply \
format binary\_little\_endian 1\.0 \
element vertex 413159 \
property float x \
property float y \
property float z \
property float nx \
property float ny \
property float nz \
property float f\_dc\_0 \
property float f\_dc\_1 \
property float f\_dc\_2 \
property float metallicFactor \
property float roughnessFactor \
property float opacity \
property float scale\_0 \
property float scale\_1 \
property float scale\_2 \
property float rot\_0 \
property float rot\_1 \
property float rot\_2 \
property float rot\_3 \
end\_header

This is quite promising, since it has the exact stuff we need: the default rot, scale, pos, opacity, dc\/color, and also the normals and metallic\+roughness
  ],
  [
okay, lets not delve into the code just yet\. I\'d like to think about 2 things: \
1) I\'d want to keep the non\-relighted version as well\. Is there a way I could pack these PBR stuff into the now unused SH floats, and have a bool that tells us if that is a relightable splatcloud or not? or will that be a very bad solution and should we just duplicate everything because of the type difference (instancing, buffers, etc\.)\. 

2) if we use the G\-buffers (which do sound very promising), will we lose all and every kind of transparency? even between splats? because that will look very bad I\'m afraid\. How does Godot\'s forward plus with deferred shading handle this? can I pass multiple normal\/pbr\/position\/opacity\/idkwhat parameters per pixel?
  ],
  [
yeah I just wanted to ask, is there a way to get the whole light(ing) data instead of trying to query the scenetree for every light, some of which might not even be active?
  ],
  [
but then how does godot solve regular transparent meshes inside forward\+?
  ],
  [
and cannot we create every splatcloud object ourselves, and then push that to Godot as one single, but partly transparent \"mesh\"?
  ],
  [
no, I mean the following: \
we render every object separately, but in the way we do it now: it blends between the splats, and stores one color, one normal\+pbr per pixel per object (all on the gpu) \
we do this separately for all the splat objects \
after that we add these buffers to Godot for it to be able to render this as it would render transparent meshes\. This way it could have transparency, and different PBR properties per pixel, the only limitation would be the 1 pbr\-property\-pack per pixel per object\.
  ],
  [
_compressed\_ply\_decoder\.gd akkori változata_ \
_standard\_ply\_decoder\.gd akkori változata_ \
_gaussian\_resource\.gd akkori változata_ \
_gaussian\_gpu\_state\_cache\.gd akkori változata_ \
_gaussian\_render\_manager\.gd akkori változata_ \
_gaussian\_renderer\.gd akkori változata_ \
_gaussian\_rendering\_device\_context\.gd akkori változata_ \
_gaussian\_scene\_registry\.gd akkori változata_ \
_gsplat\_projection\.glsl akkori változata_ \
_gsplat\_render\.glsl akkori változata_ \
Okay, let\'s do a quick working draft for the deferred shading one\. For now we can destroy the previously working spherical harmonics part, we should just focus on  \
1) importing the file type below \
2) uploading it to the gpu (we can alter the splat struct definition there \
3) make godot render it with deferred shading

we can try to import other ply files too (make roughness\/metallic\/etc something sane default, and ignore sh\'s), but its not a big problem if they fail to load either\.

Please write me the new files \/ changes needed\. I try to attach everything important\. \
I saturated the 10 file limit, but I still have: \
binary\_ply\_reader\.gd \
gaussian\_composite\.glsl \
gaussian\_compositor\_effect\.gd \
gsplat\_boundaries\.glsl \
gaussian\_import\_plugin\.gd \
Tell me if you need them\. If you do, just say it and wait one more message, and I\'ll send them\.

File type: \
ply \
format binary\_little\_endian 1\.0 \
element vertex 413159 \
property float x \
property float y \
property float z \
property float nx \
property float ny \
property float nz \
property float f\_dc\_0 \
property float f\_dc\_1 \
property float f\_dc\_2 \
property float metallicFactor \
property float roughnessFactor \
property float opacity \
property float scale\_0 \
property float scale\_1 \
property float scale\_2 \
property float rot\_0 \
property float rot\_1 \
property float rot\_2 \
property float rot\_3 \
end\_header \
��\>��\>��\<
  ],
  [
Oh, wait\. This was the method that was working pretty badly beforehand (memory problems, editor integration problems, stutters, etc)\. Can we not use the glsl script instead to output the albedo\/normal\/orm to the engine (for it to relight it), without creating a node3d and a shadermaterial? Is it possible to inject this in newer godot versions?
  ],
  [
_gaussian\_composite\.glsl akkori változata_ \
_binary\_ply\_reader\.gd akkori változata_ \
_gaussian\_compositor\_effect\.gd akkori változata_ \
_gsplat\_boundaries\.glsl akkori változata_ \
_gaussian\_import\_plugin\.gd akkori változata_ \
yes, let\'s do our own shading then\. Here are the missing files\.
  ],
  [
Okay, these were a lot of changes\. I have gotten these errors:

\-\-\- Debug adapter server started on port 6006 \-\-\- \
~~ERROR: res:\/\/addons\/gdgs\/importers\/gaussian\_import\_plugin\.gd:66 \- Parse Error: Identifier \"build\_result\" not declared in the current scope\. \
~~ERROR: res:\/\/addons\/gdgs\/runtime\/render\/gaussian\_renderer\.gd:30 \- Parse Error: Function \"get\_tree()\" not found in base self\. \
~~ERROR: res:\/\/addons\/gdgs\/runtime\/render\/gaussian\_renderer\.gd:30 \- Parse Error: Cannot infer the type of \"tree\" variable because the value doesn\'t have a set type\. \
~~ERROR: res:\/\/addons\/gdgs\/runtime\/render\/gaussian\_render\_manager\.gd:0 \- Compile Error: Failed to compile depended scripts\. \
~~ERROR: res:\/\/addons\/gdgs\/runtime\/nodes\/gaussian\_splat\_node\.gd:0 \- Compile Error: Failed to compile depended scripts\. \
~~ERROR: res:\/\/addons\/gdgs\/editor\/gizmos\/gaussian\_splat\_gizmo\_plugin\.gd:0 \- Compile Error: Failed to compile depended scripts\. \
~~ERROR: res:\/\/addons\/gdgs\/plugin\.gd:0 \- Compile Error: Failed to compile depended scripts\. \
~~ERROR: modules\/gdscript\/gdscript\.cpp:2907 \- Failed to load script \"res:\/\/addons\/gdgs\/plugin\.gd\" with error \"Compilation failed\"\. \
~~ERROR: res:\/\/addons\/gdgs\/plugin\.gd:11 \- Invalid call\. Nonexistent function \'new\' in base \'GDScript\'\. \
~~ERROR: \/root\/\@EditorNode\@18065\/\@Panel\@14\/\@Control\@40\/ShaderFile: The function \`is\_visible\_in\_tree()\` on this node can only be accessed from either the main thread or a thread group\. Use \`call\_deferred()\` instead\. \
~~ERROR: \/root\/\@EditorNode\@18065\/\@Panel\@14\/\@Control\@40\/ShaderFile: The function \`is\_visible\_in\_tree()\` on this node can only be accessed from either the main thread or a thread group\. Use \`call\_deferred()\` instead\. \
~~ERROR: res:\/\/addons\/gdgs\/importers\/decoders\/standard\_ply\_decoder\.gd:6 \- Parse Error: Preload file \"res:\/\/addons\/gdgs\/resources\/gaussian\_resource\.gd\" does not exist\. \
~~ERROR: res:\/\/addons\/gdgs\/importers\/decoders\/standard\_ply\_decoder\.gd:81 \- Parse Error: Cannot infer the type of \"res\" variable because the value doesn\'t have a set type\. \
~~ERROR: modules\/gdscript\/gdscript\.cpp:2907 \- Failed to load script \"res:\/\/addons\/gdgs\/importers\/decoders\/standard\_ply\_decoder\.gd\" with error \"Parse error\"\. \
\-\-\- GDScript language server started on port 6005 \-\-\- \
~~ERROR: Cannot open file \'res:\/\/\.godot\/imported\/teddy\.ply\-06134c725915ab499eba1b4c10403975\.res\'\. \
~~ERROR: Failed loading resource: res:\/\/\.godot\/imported\/teddy\.ply\-06134c725915ab499eba1b4c10403975\.res\. \
~~ERROR: Failed loading resource: res:\/\/models\/teddy\.ply\. \
~~ERROR: Cannot open file \'res:\/\/\.godot\/imported\/toyota\_wotire\.ply\-03f30ac771104a53a7dce9160d39c20b\.res\'\. \
~~ERROR: Failed loading resource: res:\/\/\.godot\/imported\/toyota\_wotire\.ply\-03f30ac771104a53a7dce9160d39c20b\.res\. \
~~ERROR: Failed loading resource: res:\/\/models\/toyota\_wotire\.ply\. \
~~WARNING: scene\/resources\/resource\_format\_text\.cpp:500 \- res:\/\/demo\.tscn:8 \- ext\_resource, invalid UID: uid:\/\/by67y8rqe8qs2 \- using text path instead: res:\/\/models\/DefaultFilenamepbr\.ply \
~~ERROR: Resource file not found: res:\/\/models\/DefaultFilenamepbr\.ply (expected type: Resource) \
~~WARNING: scene\/resources\/resource\_format\_text\.cpp:500 \- res:\/\/demo\.tscn:9 \- ext\_resource, invalid UID: uid:\/\/dydiabahy1fw4 \- using text path instead: res:\/\/models\/DefaultFilenamestd\.ply \
~~ERROR: Resource file not found: res:\/\/models\/DefaultFilenamestd\.ply (expected type: Resource) \
~~ERROR: scene\/main\/window\.cpp:1069 \- Attempting to make child window exclusive, but the parent window already has another exclusive child\. This window: \/root\/\@EditorNode\@18065\/\@Panel\@14\/\@DependencyErrorDialog\@809, parent window: \/root, current exclusive child window: \/root\/\@AcceptDialog\@18535 \
~~ERROR: Cannot open file \'res:\/\/\.godot\/imported\/teddy\.ply\-06134c725915ab499eba1b4c10403975\.res\'\. \
~~ERROR: Failed loading resource: res:\/\/\.godot\/imported\/teddy\.ply\-06134c725915ab499eba1b4c10403975\.res\. \
~~ERROR: Failed loading resource: res:\/\/models\/teddy\.ply\. \
~~ERROR: Cannot open file \'res:\/\/\.godot\/imported\/toyota\_wotire\.ply\-03f30ac771104a53a7dce9160d39c20b\.res\'\. \
~~ERROR: Failed loading resource: res:\/\/\.godot\/imported\/toyota\_wotire\.ply\-03f30ac771104a53a7dce9160d39c20b\.res\. \
~~ERROR: Failed loading resource: res:\/\/models\/toyota\_wotire\.ply\. \
~~WARNING: scene\/resources\/resource\_format\_text\.cpp:500 \- res:\/\/demo\.tscn:8 \- ext\_resource, invalid UID: uid:\/\/by67y8rqe8qs2 \- using text path instead: res:\/\/models\/DefaultFilenamepbr\.ply \
~~ERROR: Resource file not found: res:\/\/models\/DefaultFilenamepbr\.ply (expected type: Resource) \
~~WARNING: scene\/resources\/resource\_format\_text\.cpp:500 \- res:\/\/demo\.tscn:9 \- ext\_resource, invalid UID: uid:\/\/dydiabahy1fw4 \- using text path instead: res:\/\/models\/DefaultFilenamestd\.ply \
~~ERROR: Resource file not found: res:\/\/models\/DefaultFilenamestd\.ply (expected type: Resource) \
~~ERROR: res:\/\/addons\/gdgs\/runtime\/render\/gaussian\_render\_manager\.gd:13 \- Invalid call\. Nonexistent function \'new\' in base \'GDScript\'\. \
~~ERROR: res:\/\/addons\/gdgs\/runtime\/render\/gaussian\_render\_manager\.gd:51 \- Invalid call\. Nonexistent function \'render\_for\_compositor\' in base \'Nil\'\. \
~~ERROR: res:\/\/addons\/gdgs\/runtime\/render\/gaussian\_render\_manager\.gd:51 \- Invalid call\. Nonexistent function \'render\_for\_compositor\' in base \'Nil\'\. \
~~ERROR: res:\/\/addons\/gdgs\/runtime\/render\/gaussian\_render\_manager\.gd:51 \- Invalid call\. Nonexistent function \'render\_for\_compositor\' in base \'Nil\'\. \
~~ERROR: res:\/\/addons\/gdgs\/runtime\/render\/gaussian\_render\_manager\.gd:51 \- Invalid call\. Nonexistent function \'render\_for\_compositor\' in base \'Nil\'\.
  ],
  [
okay, we\'re getting there\. I still don\'t see anything, but now I only see these warnings:

~~WARNING: core\/variant\/variant\_utility\.cpp:1034 \- \[gdgs\] GaussianResource data size mismatch\. Expected 165263600, got 33052720 bytes\. \
~~WARNING: core\/variant\/variant\_utility\.cpp:1034 \- \[gdgs\] GaussianResource data size mismatch\. Expected 165263600, got 33052720 bytes\. \
~~WARNING: core\/variant\/variant\_utility\.cpp:1034 \- \[gdgs\] GaussianResource data size mismatch\. Expected 165263600, got 33052720 bytes\.
  ],
  [
okay wait, I\'ll read these fixes too, but the shaders have errors as well:

Failed parse: \
ERROR: 0:36: \'dims\' : undeclared identifier  \
ERROR: 0:36: \'\' : compilation terminated  \
ERROR: 2 compilation errors\.  No code generated\.

Stage \'compute\' source code: 

1        \#version 460 \
2        \#extension GL\_KHR\_shader\_subgroup\_arithmetic: enable \
3        

and \
~Failed parse: \
ERROR: 0:47: \'rasterized\_image\' : undeclared identifier  \
ERROR: 0:47: \'imageSize\' : no matching overloaded function found  \
ERROR: 0:47: \'const\' : non\-matching or non\-convertible constant type for const initializer  \
ERROR: 0:47: \'\' : compilation terminated  \
ERROR: 4 compilation errors\.  No code generated\.

Stage \'compute\' source code: 

1        \#version 460 \
2        \#extension GL\_KHR\_shader\_subgroup\_arithmetic: enable \
3        
  ],
  [
oops, sorry, my bad xd \
I used the previous one with the pasted original code cuz I feel thats safer, then re\-generating the whole thing\.

Now only one file is bad: \
Failed parse: \
ERROR: 0:151: \'get\_rect\' : no matching overloaded function found  \
ERROR: 0:151: \'\=\' :  cannot convert from \' const float\' to \' temp highp 4\-component vector of uint\' \
ERROR: 0:151: \'\' : compilation terminated  \
ERROR: 3 compilation errors\.  No code generated\.

Stage \'compute\' source code: 

1        \#version 460 \
2        \#extension GL\_KHR\_shader\_subgroup\_arithmetic: enable \
3         \
4        \#define TILE\_SIZE                (16) \
5        \#define SORT\_WORKGROUP\_SIZE      (512)
  ],
  [
okay, it doesn\'t complain now\. I only still get these warnings, which may point to why it still doesn\'t show anything:

Godot Engine v4\.6\.1\.stable\.official (c) 2007\-present Juan Linietsky, Ariel Manzur & Godot Contributors\. \
\-\-\- Debug adapter server started on port 6006 \-\-\- \
\[gdgs\] enable gaussian splatting plugin \
\[gdgs\]: importing gaussian splat file: res:\/\/models\/Susanne\_pbr\.ply \
\[gdgs\]: import complete, 413159 gaussians ready for rendering \
\-\-\- GDScript language server started on port 6005 \-\-\- \
~~WARNING: core\/variant\/variant\_utility\.cpp:1034 \- \[gdgs\] GaussianResource data size mismatch\. Expected 165263600, got 33052720 bytes\. \
~~WARNING: core\/variant\/variant\_utility\.cpp:1034 \- \[gdgs\] GaussianResource data size mismatch\. Expected 165263600, got 33052720 bytes\. \
~~WARNING: core\/variant\/variant\_utility\.cpp:1034 \- \[gdgs\] GaussianResource data size mismatch\. Expected 165263600, got 33052720 bytes\.

and no, I did fix these:

\@tool \
extends RefCounted \
class\_name GaussianSceneRegistry

const FLOATS\_PER\_SPLAT :\= 20 \
const BYTES\_PER\_FLOAT :\= 20

class NodeEntry: \
~~~~extends RefCounted

~~~~var point\_count :\= 0

\@tool \
extends RefCounted \
class\_name GaussianGpuStateCache

const RenderingDeviceContext :\= preload(\"res:\/\/addons\/gdgs\/runtime\/render\/gaussian\_rendering\_device\_context\.gd\")

const TILE\_SIZE :\= 16 \
const WORKGROUP\_SIZE :\= 512 \
const RADIX :\= 256 \
const PARTITION\_DIVISION :\= 8 \
const PARTITION\_SIZE :\= PARTITION\_DIVISION \* WORKGROUP\_SIZE \
const MAX\_RENDER\_STATES :\= 4 \
const FLOATS\_PER\_SPLAT :\= 20 \
const FLOATS\_PER\_CULLED\_SPLAT :\= 20 \
const BYTES\_PER\_FLOAT :\= 4 \
const MAX\_SORT\_ELEMENTS\_PER\_SPLAT :\= 10

However, do these fix the pre\-allocated buffer sizes (on the gpu) too?
  ],
  [
okay, wow, it is actually good now!! One thing, the sun is upside down\.
  ],
  [
okay, this is pretty good!

If we could do one more quick thing: \
the original files, with this header load fine too: \
ply \
format binary\_little\_endian 1\.0 \
element vertex 116722 \
property float x \
property float y \
property float z \
property float opacity \
property float rot\_0 \
property float rot\_1 \
property float rot\_2 \
property float rot\_3 \
property float f\_dc\_0 \
property float f\_dc\_1 \
property float f\_dc\_2 \
property float scale\_0 \
property float scale\_1 \
property float scale\_2 \
end\_header

however, they don\'t respond to the sun (and they are dark I guess since they lost the sh\-s\/don\'t get the lighting)\. One reason is definitely bc they don\'t have a normalvector\. Could we do a quick and dirty guess for the normal vector, just to see how viable it is? e\.g\. from the scale factors? (if z is the smallest extent, then e\.g\. the normal should point in that direction, or something similar)
  ],
  [
_rendered\_image\.gd akkori változata_ \
_gaussian\_splatting\_rasterizer\.gd akkori változata_ \
_ply\_importer\.gd akkori változata_ \
_render\_context\.gd akkori változata_ \
_splat\_cloud\_data\.gd akkori változata_ \
_gsplat\_boundaries\.glsl akkori változata_ \
_gsplat\_projection\.glsl akkori változata_ \
_gsplat\_render\.glsl akkori változata_ \
_main\.gdshader akkori változata_ \
_rendered\_image\.tscn akkori változata_ \
Hi again! Our own shader calculations worked fine\. However, to compare, I want to quickly test the other implementation too, where we give godot the parameters for deferred shading\. We will start from a DIFFERENT codebase this time, I rolled back to where we still had the fullscreen quad, so we don\'t need to reimplement that instead of the compositoreffect\. I will give you the code\. Please tell me, where we need to modify\. (RenderedImage is an autoload, and it works in the editor too\.) \
Please also suggest me a fix for the line that redraws every process() to skip the drawing in case there is no real redraw \/ the engine stalls the rendering, since it creates big hiccups\.
  ],
  [
Nice! Please, create the code that makes the deferred shading possible too!
  ],
  [
Okay, it runs now, but throws some errors:

Godot Engine v4\.6\.1\.stable\.official (c) 2007\-present Juan Linietsky, Ariel Manzur & Godot Contributors\. \
\-\-\- Debug adapter server started on port 6006 \-\-\- \
\-\-\- GDScript language server started on port 6005 \-\-\- \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/scripts\/gaussian\_splatting\_rasterizer\.gd:35 \- Invalid access to property or key \'device\' on a base object of type \'Nil\'\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/scripts\/gaussian\_splatting\_rasterizer\.gd:35 \- Invalid access to property or key \'device\' on a base object of type \'Nil\'\. \
~~ERROR: Can\'t create buffer of size: 0, error \-3\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:844 \- Condition \"!buffer\.driver\_id\" is true\. Returning: RID() \
~~ERROR: Width must be equal or greater than 1 for all textures \
~~ERROR: Width must be equal or greater than 1 for all textures \
~~ERROR: Width must be equal or greater than 1 for all textures \
~~ERROR: Storage buffer supplied (binding: 2) must provide one ID (0 provided)\. \
~~ERROR: Storage buffer supplied (binding: 2) must provide one ID (0 provided)\. \
~~ERROR: Buffer argument is not a valid buffer of any type\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Uniforms were never supplied for set (0) at the time of drawing, which are required by the pipeline\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Dispatch amount of X compute groups (0) is zero\. \
~~ERROR: Buffer argument is not a valid buffer of any type\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Uniforms were never supplied for set (0) at the time of drawing, which are required by the pipeline\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Dispatch amount of X compute groups (0) is zero\. \
~~ERROR: Buffer argument is not a valid buffer of any type\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Uniforms were never supplied for set (0) at the time of drawing, which are required by the pipeline\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Dispatch amount of X compute groups (0) is zero\. \
~~ERROR: Buffer argument is not a valid buffer of any type\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Uniforms were never supplied for set (0) at the time of drawing, which are required by the pipeline\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Dispatch amount of X compute groups (0) is zero\. \
~~ERROR: Buffer argument is not a valid buffer of any type\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Uniforms were never supplied for set (0) at the time of drawing, which are required by the pipeline\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Dispatch amount of X compute groups (0) is zero\. \
~~ERROR: Buffer argument is not a valid buffer of any type\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Uniforms were never supplied for set (0) at the time of drawing, which are required by the pipeline\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Dispatch amount of X compute groups (0) is zero\. \
~~ERROR: Buffer argument is not a valid buffer of any type\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Uniforms were never supplied for set (0) at the time of drawing, which are required by the pipeline\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Dispatch amount of X compute groups (0) is zero\. \
~~ERROR: Buffer argument is not a valid buffer of any type\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Uniforms were never supplied for set (0) at the time of drawing, which are required by the pipeline\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Dispatch amount of X compute groups (0) is zero\. \
~~ERROR: Buffer argument is not a valid buffer of any type\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Uniforms were never supplied for set (0) at the time of drawing, which are required by the pipeline\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Dispatch amount of X compute groups (0) is zero\. \
~~ERROR: Buffer argument is not a valid buffer of any type\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Uniforms were never supplied for set (0) at the time of drawing, which are required by the pipeline\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Dispatch amount of X compute groups (0) is zero\. \
~~ERROR: Buffer argument is not a valid buffer of any type\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Uniforms were never supplied for set (0) at the time of drawing, which are required by the pipeline\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Dispatch amount of X compute groups (0) is zero\. \
~~ERROR: Buffer argument is not a valid buffer of any type\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Uniforms were never supplied for set (0) at the time of drawing, which are required by the pipeline\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Dispatch amount of X compute groups (0) is zero\. \
~~ERROR: Buffer argument is not a valid buffer of any type\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Uniforms were never supplied for set (0) at the time of drawing, which are required by the pipeline\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Dispatch amount of X compute groups (0) is zero\. \
~~ERROR: Buffer argument is not a valid buffer of any type\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Uniforms were never supplied for set (0) at the time of drawing, which are required by the pipeline\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Dispatch amount of X compute groups (0) is zero\. \
~~ERROR: Buffer argument is not a valid buffer of any type\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Uniforms were never supplied for set (0) at the time of drawing, which are required by the pipeline\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Dispatch amount of X compute groups (0) is zero\. \
~~ERROR: Buffer argument is not a valid buffer of any type\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Uniforms were never supplied for set (0) at the time of drawing, which are required by the pipeline\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Dispatch amount of X compute groups (0) is zero\. \
~~ERROR: Buffer argument is not a valid buffer of any type\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Uniforms were never supplied for set (0) at the time of drawing, which are required by the pipeline\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5473 \- Parameter \"uniform\_set\" is null\. \
~~ERROR: Dispatch amount of X compute groups (0) is zero\.

and also, I see: \
the non\-splat objects, or at least some kind of siluette of them \
the \"splats\" are huge, and purple\-black in the very front of the screen, 4x4 chessboard\-style covers the whole screen
  ],
  [
_gaussian\_splatting\_rasterizer\.gd akkori változata_ \
ive updated the setter, but the init\_gpu i cant, what do you mean there?
  ],
  [
Godot Engine v4\.6\.1\.stable\.official (c) 2007\-present Juan Linietsky, Ariel Manzur & Godot Contributors\. \
\-\-\- Debug adapter server started on port 6006 \-\-\- \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/scripts\/gaussian\_splatting\_rasterizer\.gd:86 \- Parse Error: Cannot infer the type of \"num\_sort\_elements\_max\" variable because the value doesn\'t have a set type\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/scripts\/gaussian\_splatting\_rasterizer\.gd:87 \- Parse Error: Cannot infer the type of \"num\_partitions\" variable because the value doesn\'t have a set type\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/rendered\_image\.gd:0 \- Compile Error: Failed to compile depended scripts\. \
~~ERROR: modules\/gdscript\/gdscript\.cpp:2907 \- Failed to load script \"res:\/\/addons\/gsplat\-nodes\/rendered\_image\.gd\" with error \"Compilation failed\"\. \
\-\-\- GDScript language server started on port 6005 \-\-\- \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/rendered\_image\.gd:69 \- Invalid call\. Nonexistent function \'new\' in base \'GDScript\'\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/rendered\_image\.gd:81 \- Invalid assignment of property or key \'is\_loaded\' with value of type \'bool\' on a base object of type \'Nil\'\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/rendered\_image\.gd:81 \- Invalid assignment of property or key \'is\_loaded\' with value of type \'bool\' on a base object of type \'Nil\'\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/rendered\_image\.gd:81 \- Invalid assignment of property or key \'is\_loaded\' with value of type \'bool\' on a base object of type \'Nil\'\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/rendered\_image\.gd:81 \- Invalid assignment of property or key \'is\_loaded\' with value of type \'bool\' on a base object of type \'Nil\'\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/rendered\_image\.gd:81 \- Invalid assignment of property or key \'is\_loaded\' with value of type \'bool\' on a base object of type \'Nil\'\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/rendered\_image\.gd:81 \- Invalid assignment of property or key \'is\_loaded\' with value of type \'bool\' on a base object of type \'Nil\'\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/rendered\_image\.gd:81 \- Invalid assignment of property or key \'is\_loaded\' with value of type \'bool\' on a base object of type \'Nil\'\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/rendered\_image\.gd:81 \- Invalid assignment of property or key \'is\_loaded\' with value of type \'bool\' on a base object of type \'Nil\'\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/rendered\_image\.gd:81 \- Invalid assignment of property or key \'is\_loaded\' with value of type \'bool\' on a base object of type \'Nil\'\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/rendered\_image\.gd:81 \- Invalid assignment of property or key \'is\_loaded\' with value of type \'bool\' on a base object of type \'Nil\'\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/rendered\_image\.gd:81 \- Invalid assignment of property or key \'is\_loaded\' with value of type \'bool\' on a base object of type \'Nil\'\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/rendered\_image\.gd:81 \- Invalid assignment of property or key \'is\_loaded\' with value of type \'bool\' on a base object of type \'Nil\'\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/rendered\_image\.gd:81 \- Invalid assignment of property or key \'is\_loaded\' with value of type \'bool\' on a base object of type \'Nil\'\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/rendered\_image\.gd:81 \- Invalid assignment of property or key \'is\_loaded\' with value of type \'bool\' on a base object of type \'Nil\'\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/rendered\_image\.gd:81 \- Invalid assignment of property or key \'is\_loaded\' with value of type \'bool\' on a base object of type \'Nil\'\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/rendered\_image\.gd:81 \- Invalid assignment of property or key \'is\_loaded\' with value of type \'bool\' on a base object of type \'Nil\'\.
  ],
  [
okay, now I can see the regular meshes, but they are funnily lagging a lot, even though the background sky isnt\.

Godot Engine v4\.6\.1\.stable\.official (c) 2007\-present Juan Linietsky, Ariel Manzur & Godot Contributors\. \
\-\-\- Debug adapter server started on port 6006 \-\-\- \
\-\-\- GDScript language server started on port 6005 \-\-\- \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/scripts\/gaussian\_splatting\_rasterizer\.gd:117 \- Invalid assignment of property or key \'texture\_rd\_rid\' with value of type \'RID\' on a base object of type \'Nil\'\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/scripts\/gaussian\_splatting\_rasterizer\.gd:157 \- Invalid access to property or key \'gsplat\_projection\' on a base object of type \'Dictionary\'\. \
~~ERROR: Updating textures is forbidden during creation of a draw or compute list \
~~ERROR: Updating textures is forbidden during creation of a draw or compute list \
~~ERROR: Updating textures is forbidden during creation of a draw or compute list \
~~ERROR: Updating textures is forbidden during creation of a draw or compute list \
~~ERROR: Updating textures is forbidden during creation of a draw or compute list \
~~ERROR: Updating textures is forbidden during creation of a draw or compute list \
~~ERROR: Updating textures is forbidden during creation of a draw or compute list \
~~ERROR: Updating textures is forbidden during creation of a draw or compute list \
~~ERROR: Updating textures is forbidden during creation of a draw or compute list \
~~ERROR: Updating textures is forbidden during creation of a draw or compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Only one draw\/compute list can be active at the same time\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5387 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5464 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5464 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5503 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5526 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/scripts\/gaussian\_splatting\_rasterizer\.gd:157 \- Invalid access to property or key \'gsplat\_projection\' on a base object of type \'Dictionary\'\. \
~~ERROR: Updating textures is forbidden during creation of a draw or compute list \
~~ERROR: Updating textures is forbidden during creation of a draw or compute list \
~~ERROR: Updating textures is forbidden during creation of a draw or compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Only one draw\/compute list can be active at the same time\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5387 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5464 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5464 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5503 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5526 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/scripts\/gaussian\_splatting\_rasterizer\.gd:157 \- Invalid access to property or key \'gsplat\_projection\' on a base object of type \'Dictionary\'\. \
~~ERROR: Updating textures is forbidden during creation of a draw or compute list \
~~ERROR: Updating textures is forbidden during creation of a draw or compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Only one draw\/compute list can be active at the same time\. \
~~ \
~~\.\.\. \
~~ \
~~ \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5387 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5464 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5464 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5503 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5644 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/scripts\/gaussian\_splatting\_rasterizer\.gd:157 \- Invalid access to property or key \'gsplat\_projection\' on a base object of type \'Dictionary\'\. \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Only one draw\/compute list can be active at the same time\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5387 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5464 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5464 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5503 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5644 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/scripts\/gaussian\_splatting\_rasterizer\.gd:157 \- Invalid access to property or key \'gsplat\_projection\' on a base object of type \'Dictionary\'\. \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Only one draw\/compute list can be active at the same time\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5387 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5464 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5464 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5503 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5644 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: res:\/\/addons\/gsplat\-nodes\/scripts\/gaussian\_splatting\_rasterizer\.gd:157 \- Invalid access to property or key \'gsplat\_projection\' on a base object of type \'Dictionary\'\. \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Updating buffers is forbidden during creation of a compute list \
~~ERROR: Only one draw\/compute list can be active at the same time\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5387 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5464 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5464 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5503 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\. \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:5644 \- Condition \"p\_list !\= ID\_TYPE\_COMPUTE\_LIST\" is true\.
  ],
  [
why dont we create a render\_texture then as well?
  ],
  [
okay, now it is pretty good! basically no errors, (just some attempted to free invalid id or smth), and I can see the regular meshes and the gs clouds, they also have some lighting\. It is not perfect though, the lighting on Suzanne is kindof affected by the camera position, which I dont think it should be, and also it is kinda lit from the bottom instead of the top\. Actually, looking at it closely it looks like this: \
1) lit from the bottom instead of top \
2) lit from a smaller rectangle than the screen \- do we resize the orm\/normal buffers too?

what changes are needed?
  ],
  [
okay, it did something, specifically I think it is now lit from upwards\. \
However: it is (now? maybe, I didn\'t notice it previously) now disregarding depth value, the meshes in the screen are always behind\. that is not good, we do need the depth value\. \
2) it is still only lit in the bottom half of the screen, and horizontally also the right side is a bit unlit, as it was previously\. This top and left part unlit is constant, so whereever I move the camera, it is still the top\+left part that is unlit\.
  ],
  [
okay, it did something, specifically I think it is now lit from upwards\. \
However: it is (now? maybe, I didn\'t notice it previously) now disregarding depth value, the meshes in the screen are always behind\. that is not good, we do need the depth value\. \
2) it is still only lit in the bottom half of the screen, and horizontally also the right side is a bit unlit, as it was previously\. This top and left part unlit is constant, so whereever I move the camera, it is still the top\+left part that is unlit\. \
\-\- sorry, left side is unlit\. Maybe 10% of the horizontal space
  ],
  [
lets not add a whole ass texture, and just use the same method used previously, where we passed the depth as the alpha\. Also, since we cannot do alpha blending with the deferred shader anyways, we might as well just use the info from the very first splat, and skip all alpha blending, what do you think? Ehh, maybe we can keep the blending, it may help with large flat planes\.
  ],
  [
_gsplat\_render\.glsl akkori változata_ \
Failed parse: \
ERROR: 0:100: \'first\_hit\_depth\' : undeclared identifier  \
ERROR: 0:100: \'\' : compilation terminated  \
ERROR: 2 compilation errors\.  No code generated\.
  ],
  [
it doesn\'t work well, only around x\=\=0 splats does it get behind mesh objects, and also at times when it should be in front\. The other splats (pos x!\=0) are still always in front\.
  ],
  [
_gsplat\_projection\.glsl akkori változata_ \
_gsplat\_render\.glsl akkori változata_ \
_main\.gdshader akkori változata_ \
_main\.gdshader\.old akkori változata_ \
_gsplat\_render\.glsl\.old akkori változata_ \
_gsplat\_projection\.glsl\.old akkori változata_ \
okay, I am not sure I would want to do this\. Instead do the following: \
\- I am attaching my current files \
\- I am also attaching the old files (\.old) where the depth actually worked\. Please compare the two, and tell me what to put into the newer files to get the depth working again, in the same way that the old one worked\. \
Our modifications elsewhere don\'t change the way we can pass the depth value on, right?
  ],
  [
Nice, depth is good now! Now I think we only have one bug: \
the shading textures are not large enough, or not well spaced compared to the albedo\. The top 40% of the screen (no matter where I look) and the left 10% is unshaded\.
  ],
  [
no, that is not even close\. I have narrowed down the problem by a lot: having this main\.gdshader (which doesn\'t have any of the gsplat \/ texture logic) still has the issue:

shader\_type spatial; \
render\_mode blend\_mix, depth\_draw\_opaque, cull\_disabled;

\/\/uniform sampler2D render\_texture : source\_color, filter\_linear\_mipmap\_anisotropic; \
\/\/uniform sampler2D normal\_texture; \
\/\/uniform sampler2D orm\_texture;

vec3 srgb\_to\_linear(vec3 x) { \
~~~~vec3 higher \= pow((x \+ 0\.055) \/ 1\.055, vec3(2\.4)); \
~~~~vec3 lower \= x \/ 12\.92; \
~~~~return mix(higher, lower, lessThan(x, vec3(0\.04045))); \
}

void vertex() { \
~~~~POSITION \= vec4(VERTEX\.xy, 1\.0, 1\.0); \
}

void fragment() { \
~~~~\/\/vec4 albedo\_alpha \= texture(orm\_texture, SCREEN\_UV); \
~~~~\/\/if (albedo\_alpha\.a \< 0\.1) discard; 

~~~~\/\/ALBEDO \= srgb\_to\_linear(albedo\_alpha\.rgb); \
~~~~\/\/ALPHA \= albedo\_alpha\.a; \
~~~~ALBEDO \= vec3(1,1,0); \
~~~~ALPHA \= 1\.0; \
~~~~if (SCREEN\_UV\.x \* SCREEN\_UV\.x \+ SCREEN\_UV\.y \* SCREEN\_UV\.y \> 1\.0) \
~~~~~~~~ALPHA \= 0\.0; \
~~~~ \
~~~~\/\/vec4 normal\_and\_depth \= texture(render\_texture, SCREEN\_UV); \
~~~~ \
~~~~\/\/ USE EXACT OLD DEPTH BEHAVIOR: \
~~~~\/\/DEPTH \= normal\_and\_depth\.a; \
~~~~ \
~~~~\/\/ Keep the normal flip to ensure lighting doesn\'t hit the back faces \
~~~~\/\/vec3 world\_normal \= normal\_and\_depth\.xyz; \
~~~~\/\/world\_normal\.x \= \-world\_normal\.x; \
~~~~\/\/world\_normal\.y \= \-world\_normal\.y; \
~~~~NORMAL \= (VIEW\_MATRIX \* vec4(0,1,0, 0\.0))\.xyz; \
~~~~ \
~~~~\/\/vec3 orm \= texture(normal\_texture, SCREEN\_UV)\.rgb; \
~~~~\/\/AO \= orm\.r; \
~~~~\/\/ROUGHNESS \= orm\.g; \
~~~~\/\/METALLIC \= orm\.b; \
}

with this I can see a 1\/4 circle (middle point is top\-left), and the bottom 55% is shaded properly, the top 45% isn\'t\. What could cause the problem?
  ],
  [
Error at line 54: Constants cannot be modified\.
  ],
  [
_main\.gdshader akkori változata_ \
hi, long time no see\. lets still look at the godot deferred shaded shading, we still have a bug\. If I light it with a spotlight, the whole thing is lit as if their position was at the middle of the gsplat cloud, and this way the spotlight\'s light doesn\'t gradually decrease as the angle towards the spotlight increases\. Also, at the edges there is a harsh edge, since I guess Godot would optimize that part, since there wouldn\'t need to be any light anyway\. How do we take the actual world position of the splats into account?
  ],
  [
okay, this looks pretty promising, the only problem is now at the edges\. the resolution is lower, and the rectangles that don\'t fully cover Suzanne are not lit properly\. Can we easily extend the depth of the subdivision for the ones that don\'t have a depth value, so that the neighboring depth value is used? It would be enough for one neighbor only\. I think this would solve it\.
  ],
  [
sadly I don\'t think this one helped at all\.
  ],
  [
_gsplat\_boundaries\.glsl akkori változata_ \
_gsplat\_projection\.glsl akkori változata_ \
_gsplat\_render\.glsl akkori változata_ \
still no luck, you sure that depth 1\.0 and 0\.0 aren\'t switched up? these are the files the depth comes from\.
  ],
  [
yup, that\'s more like it! it works pretty well now\. One thing, if I look at the edges at a sharp angle, that are lit directly from their front, I still see some minor artifacts (some pixels aren\'t lit that should be), could we correct those too? probably still some shenanigans with this net\-that\-is\-cast\-over\-the\-gsplatcloud not being perfect
  ],
  [
yeah no, this one was way worse than the previous one\. It has a lot of artifacts, even in the middle of Suzanne where previously it was good\.
  ],
  [
okay, lets leave that as is\. \
Now, please look up the glTF gaussian splatting format on the internet: \
https:\/\/www\.khronos\.org\/news\/press\/gltf\-gaussian\-splatting\-press\-release \
How widespread is it, what is the current state of it, where are sample files, how straight forward would be to implement it, what compression do we need inside GDScript if any\.
  ],
  [
_README\.md akkori változata_ \
_gsplat\-nodes\.gd akkori változata_ \
_ply\_importer\.gd akkori változata_ \
_splat\_cloud\_data\.gd akkori változata_ \
okay, this looks good\. A couple of notes: I did not find a sample\-models, or any similar folder, so we will still need to find samples\. But our next step will be to implement the Godot part\. The uncompressed gltf\/glb format will be good\. I attach the readme of the above mentioned extension, so that you have the exact extension description\. \
I also attach the relevant GDScript code (tell me if anything is missing)\. We will start with a previous version of the code, since that is simpler to work with\. \
Please create a gltf\_importer\.gd file that works like the ply one, and imports the splat\_cloud\_data as the other parts of the code can read it\.
  ],
  [
nice, looks good! but I really cannot find any sample files, please look up some for me!
  ],
  [
okay, I have a glb file that kinda looks good, but I cannot drag\-n\-drop it in the editor to the splat data attribute of the splatcloud3d node (it waits for type SplatCloudData)\. What could be the problem?
  ],
  [
1) I did the first one already, and 2) I think we have tried that before, and it only works for builtin types, that\'s why it is resource, and since the ply one works, thats not the problem anyway\. Any other suggestions? \
another note: before reimporting, I could see the model imported as a scene, and it did fall back to regular point rendering, and I could see the model, hence I feel like the model should be fine (at least the dc colors and the positions)\. After reimporting, the icon changed, and it looked like a successful import \- but as now I see, it is in fact unsuccessful: \
ERROR: res:\/\/addons\/gsplat\-nodes\/scripts\/gltf\_importer\.gd:160 \- Invalid assignment of property or key \'split\' with value of type \'Array\' on a base object of type \'Resource (SplatCloudData)\'\. \
~~ERROR: core\/io\/file\_access\.cpp:1002 \- Condition \"f\.is\_null()\" is true\. Continuing\. \
so this will be the cause\.
  ],
  [
okay, now there are actually no errors, and I can drag\-n\-drop the file onto the node, but there is nothing to see\. 1) what could cause this? 2) where should I put a print that prints parts of the ply\+gltf \-imported splatclouddata\'s, to help compare the 2 resources and find the differences that could point us in the right direction?
  ],
  [
Set splat\_data \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:6422 \- Attempted to free invalid ID: 827554298593540 \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:6422 \- Attempted to free invalid ID: 827550003626259

\-\-\- SPLAT DATA DEBUG \-\-\- \
Total Points: 186814 \
Vertex 0: { &\"x\": 1\.20339953899384, &\"y\": \-0\.89475619792938, &\"z\": 1\.68832993507385, &\"nx\": 0\.0, &\"ny\": 0\.0, &\"nz\": 0\.0, &\"f\_dc\_0\": 0\.54911315441132, &\"f\_dc\_1\": 0\.61862117052078, &\"f\_dc\_2\": 0\.36839237809181, &\"f\_rest\_0\": 0\.0, &\"f\_rest\_1\": 0\.0, &\"f\_rest\_2\": \-4\.43081665039062, &\"f\_rest\_3\": \-6\.62255907058716, &\"f\_rest\_4\": \-1\.52024722099304, &\"f\_rest\_5\": \-1\.64595031738281, &\"f\_rest\_6\": \-0\.31087517738342, &\"f\_rest\_7\": 0\.18568336963654, &\"f\_rest\_8\": 0\.3328466117382, &\"f\_rest\_9\": \-0\.87068450450897, &\"f\_rest\_10\": 0\.0, &\"f\_rest\_11\": 0\.0, &\"f\_rest\_12\": 0\.0, &\"f\_rest\_13\": 0\.0, &\"f\_rest\_14\": 0\.0, &\"f\_rest\_15\": 0\.0, &\"f\_rest\_16\": 0\.0, &\"f\_rest\_17\": 0\.0, &\"f\_rest\_18\": 0\.0, &\"f\_rest\_19\": 0\.0, &\"f\_rest\_20\": 0\.0, &\"f\_rest\_21\": 0\.0, &\"f\_rest\_22\": 0\.0, &\"f\_rest\_23\": 0\.0, &\"f\_rest\_24\": 0\.0, &\"f\_rest\_25\": 0\.0, &\"f\_rest\_26\": 0\.0, &\"f\_rest\_27\": 0\.0, &\"f\_rest\_28\": 0\.0, &\"f\_rest\_29\": 0\.0, &\"f\_rest\_30\": 0\.0, &\"f\_rest\_31\": 0\.0, &\"f\_rest\_32\": 0\.0, &\"f\_rest\_33\": 0\.0, &\"f\_rest\_34\": 0\.0, &\"f\_rest\_35\": 0\.0, &\"f\_rest\_36\": 0\.0, &\"f\_rest\_37\": 0\.0, &\"f\_rest\_38\": 0\.0, &\"f\_rest\_39\": 0\.0, &\"f\_rest\_40\": 0\.0, &\"f\_rest\_41\": 0\.0, &\"f\_rest\_42\": 0\.0, &\"f\_rest\_43\": 0\.0, &\"f\_rest\_44\": 0\.0, &\"opacity\": 0\.0, &\"scale\_0\": 0\.0, &\"scale\_1\": 0\.0, &\"scale\_2\": 0\.0, &\"rot\_0\": 0\.0, &\"rot\_1\": 0\.0, &\"rot\_2\": 0\.0, &\"rot\_3\": 0\.0 } \
Vertex 1: { &\"x\": 0\.23175203800201, &\"y\": \-0\.39204746484756, &\"z\": 1\.79703676700592, &\"nx\": 0\.0, &\"ny\": 0\.0, &\"nz\": 0\.0, &\"f\_dc\_0\": \-1\.77245390415192, &\"f\_dc\_1\": \-1\.66124105453491, &\"f\_dc\_2\": \-1\.77245390415192, &\"f\_rest\_0\": 0\.0, &\"f\_rest\_1\": 0\.0, &\"f\_rest\_2\": \-4\.84024238586426, &\"f\_rest\_3\": \-5\.52290439605713, &\"f\_rest\_4\": \-8\.57001972198486, &\"f\_rest\_5\": \-3\.04274415969849, &\"f\_rest\_6\": 0\.6250067949295, &\"f\_rest\_7\": \-0\.39272540807724, &\"f\_rest\_8\": 0\.25670486688614, &\"f\_rest\_9\": \-0\.62388771772385, &\"f\_rest\_10\": 0\.0, &\"f\_rest\_11\": 0\.0, &\"f\_rest\_12\": 0\.0, &\"f\_rest\_13\": 0\.0, &\"f\_rest\_14\": 0\.0, &\"f\_rest\_15\": 0\.0, &\"f\_rest\_16\": 0\.0, &\"f\_rest\_17\": 0\.0, &\"f\_rest\_18\": 0\.0, &\"f\_rest\_19\": 0\.0, &\"f\_rest\_20\": 0\.0, &\"f\_rest\_21\": 0\.0, &\"f\_rest\_22\": 0\.0, &\"f\_rest\_23\": 0\.0, &\"f\_rest\_24\": 0\.0, &\"f\_rest\_25\": 0\.0, &\"f\_rest\_26\": 0\.0, &\"f\_rest\_27\": 0\.0, &\"f\_rest\_28\": 0\.0, &\"f\_rest\_29\": 0\.0, &\"f\_rest\_30\": 0\.0, &\"f\_rest\_31\": 0\.0, &\"f\_rest\_32\": 0\.0, &\"f\_rest\_33\": 0\.0, &\"f\_rest\_34\": 0\.0, &\"f\_rest\_35\": 0\.0, &\"f\_rest\_36\": 0\.0, &\"f\_rest\_37\": 0\.0, &\"f\_rest\_38\": 0\.0, &\"f\_rest\_39\": 0\.0, &\"f\_rest\_40\": 0\.0, &\"f\_rest\_41\": 0\.0, &\"f\_rest\_42\": 0\.0, &\"f\_rest\_43\": 0\.0, &\"f\_rest\_44\": 0\.0, &\"opacity\": 0\.0, &\"scale\_0\": 0\.0, &\"scale\_1\": 0\.0, &\"scale\_2\": 0\.0, &\"rot\_0\": 0\.0, &\"rot\_1\": 0\.0, &\"rot\_2\": 0\.0, &\"rot\_3\": 0\.0 } \
Vertex 2: { &\"x\": 0\.2159501761198, &\"y\": \-0\.4155185520649, &\"z\": 1\.81503283977509, &\"nx\": 0\.0, &\"ny\": 0\.0, &\"nz\": 0\.0, &\"f\_dc\_0\": \-1\.77245390415192, &\"f\_dc\_1\": \-1\.48052024841309, &\"f\_dc\_2\": \-1\.77245390415192, &\"f\_rest\_0\": 0\.0, &\"f\_rest\_1\": 0\.0, &\"f\_rest\_2\": \-4\.84024238586426, &\"f\_rest\_3\": \-5\.50646448135376, &\"f\_rest\_4\": \-8\.59640598297119, &\"f\_rest\_5\": \-3\.06352996826172, &\"f\_rest\_6\": 0\.534135222435, &\"f\_rest\_7\": \-0\.42906764149666, &\"f\_rest\_8\": 0\.32470232248306, &\"f\_rest\_9\": \-0\.65204977989197, &\"f\_rest\_10\": 0\.0, &\"f\_rest\_11\": 0\.0, &\"f\_rest\_12\": 0\.0, &\"f\_rest\_13\": 0\.0, &\"f\_rest\_14\": 0\.0, &\"f\_rest\_15\": 0\.0, &\"f\_rest\_16\": 0\.0, &\"f\_rest\_17\": 0\.0, &\"f\_rest\_18\": 0\.0, &\"f\_rest\_19\": 0\.0, &\"f\_rest\_20\": 0\.0, &\"f\_rest\_21\": 0\.0, &\"f\_rest\_22\": 0\.0, &\"f\_rest\_23\": 0\.0, &\"f\_rest\_24\": 0\.0, &\"f\_rest\_25\": 0\.0, &\"f\_rest\_26\": 0\.0, &\"f\_rest\_27\": 0\.0, &\"f\_rest\_28\": 0\.0, &\"f\_rest\_29\": 0\.0, &\"f\_rest\_30\": 0\.0, &\"f\_rest\_31\": 0\.0, &\"f\_rest\_32\": 0\.0, &\"f\_rest\_33\": 0\.0, &\"f\_rest\_34\": 0\.0, &\"f\_rest\_35\": 0\.0, &\"f\_rest\_36\": 0\.0, &\"f\_rest\_37\": 0\.0, &\"f\_rest\_38\": 0\.0, &\"f\_rest\_39\": 0\.0, &\"f\_rest\_40\": 0\.0, &\"f\_rest\_41\": 0\.0, &\"f\_rest\_42\": 0\.0, &\"f\_rest\_43\": 0\.0, &\"f\_rest\_44\": 0\.0, &\"opacity\": 0\.0, &\"scale\_0\": 0\.0, &\"scale\_1\": 0\.0, &\"scale\_2\": 0\.0, &\"rot\_0\": 0\.0, &\"rot\_1\": 0\.0, &\"rot\_2\": 0\.0, &\"rot\_3\": 0\.0 } \
\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-

Set splat\_data \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:6422 \- Attempted to free invalid ID: 1580818547867918 \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:6422 \- Attempted to free invalid ID: 1580814252900612 \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:6422 \- Attempted to free invalid ID: 1578434841018638 \
~~ERROR: servers\/rendering\/rendering\_device\.cpp:6422 \- Attempted to free invalid ID: 1578430546051347

\-\-\- SPLAT DATA DEBUG \-\-\- \
Total Points: 210129 \
Vertex 0: { &\"x\": 1\.20339953899384, &\"y\": \-0\.89475619792938, &\"z\": 1\.68832993507385, &\"nx\": 0\.0, &\"ny\": 0\.0, &\"nz\": 0\.0, &\"f\_dc\_0\": 0\.54911315441132, &\"f\_dc\_1\": 0\.61862117052078, &\"f\_dc\_2\": 0\.36839237809181, &\"f\_rest\_0\": 0\.0, &\"f\_rest\_1\": 0\.0, &\"f\_rest\_2\": \-4\.43081665039062, &\"f\_rest\_3\": \-6\.62255907058716, &\"f\_rest\_4\": \-1\.52024722099304, &\"f\_rest\_5\": \-1\.64595031738281, &\"f\_rest\_6\": \-0\.31087517738342, &\"f\_rest\_7\": 0\.18568336963654, &\"f\_rest\_8\": 0\.3328466117382, &\"f\_rest\_9\": \-0\.87068450450897, &\"f\_rest\_10\": 0\.0, &\"f\_rest\_11\": 0\.0, &\"f\_rest\_12\": 0\.0, &\"f\_rest\_13\": 0\.0, &\"f\_rest\_14\": 0\.0, &\"f\_rest\_15\": 0\.0, &\"f\_rest\_16\": 0\.0, &\"f\_rest\_17\": 0\.0, &\"f\_rest\_18\": 0\.0, &\"f\_rest\_19\": 0\.0, &\"f\_rest\_20\": 0\.0, &\"f\_rest\_21\": 0\.0, &\"f\_rest\_22\": 0\.0, &\"f\_rest\_23\": 0\.0, &\"f\_rest\_24\": 0\.0, &\"f\_rest\_25\": 0\.0, &\"f\_rest\_26\": 0\.0, &\"f\_rest\_27\": 0\.0, &\"f\_rest\_28\": 0\.0, &\"f\_rest\_29\": 0\.0, &\"f\_rest\_30\": 0\.0, &\"f\_rest\_31\": 0\.0, &\"f\_rest\_32\": 0\.0, &\"f\_rest\_33\": 0\.0, &\"f\_rest\_34\": 0\.0, &\"f\_rest\_35\": 0\.0, &\"f\_rest\_36\": 0\.0, &\"f\_rest\_37\": 0\.0, &\"f\_rest\_38\": 0\.0, &\"f\_rest\_39\": 0\.0, &\"f\_rest\_40\": 0\.0, &\"f\_rest\_41\": 0\.0, &\"f\_rest\_42\": 0\.0, &\"f\_rest\_43\": 0\.0, &\"f\_rest\_44\": 0\.0, &\"opacity\": 0\.0, &\"scale\_0\": 0\.0, &\"scale\_1\": 0\.0, &\"scale\_2\": 0\.0, &\"rot\_0\": 0\.0, &\"rot\_1\": 0\.0, &\"rot\_2\": 0\.0, &\"rot\_3\": 0\.0 } \
Vertex 1: { &\"x\": 0\.23175203800201, &\"y\": \-0\.39204746484756, &\"z\": 1\.79703676700592, &\"nx\": 0\.0, &\"ny\": 0\.0, &\"nz\": 0\.0, &\"f\_dc\_0\": \-1\.77245390415192, &\"f\_dc\_1\": \-1\.66124105453491, &\"f\_dc\_2\": \-1\.77245390415192, &\"f\_rest\_0\": 0\.0, &\"f\_rest\_1\": 0\.0, &\"f\_rest\_2\": \-4\.84024238586426, &\"f\_rest\_3\": \-5\.52290439605713, &\"f\_rest\_4\": \-8\.57001972198486, &\"f\_rest\_5\": \-3\.04274415969849, &\"f\_rest\_6\": 0\.6250067949295, &\"f\_rest\_7\": \-0\.39272540807724, &\"f\_rest\_8\": 0\.25670486688614, &\"f\_rest\_9\": \-0\.62388771772385, &\"f\_rest\_10\": 0\.0, &\"f\_rest\_11\": 0\.0, &\"f\_rest\_12\": 0\.0, &\"f\_rest\_13\": 0\.0, &\"f\_rest\_14\": 0\.0, &\"f\_rest\_15\": 0\.0, &\"f\_rest\_16\": 0\.0, &\"f\_rest\_17\": 0\.0, &\"f\_rest\_18\": 0\.0, &\"f\_rest\_19\": 0\.0, &\"f\_rest\_20\": 0\.0, &\"f\_rest\_21\": 0\.0, &\"f\_rest\_22\": 0\.0, &\"f\_rest\_23\": 0\.0, &\"f\_rest\_24\": 0\.0, &\"f\_rest\_25\": 0\.0, &\"f\_rest\_26\": 0\.0, &\"f\_rest\_27\": 0\.0, &\"f\_rest\_28\": 0\.0, &\"f\_rest\_29\": 0\.0, &\"f\_rest\_30\": 0\.0, &\"f\_rest\_31\": 0\.0, &\"f\_rest\_32\": 0\.0, &\"f\_rest\_33\": 0\.0, &\"f\_rest\_34\": 0\.0, &\"f\_rest\_35\": 0\.0, &\"f\_rest\_36\": 0\.0, &\"f\_rest\_37\": 0\.0, &\"f\_rest\_38\": 0\.0, &\"f\_rest\_39\": 0\.0, &\"f\_rest\_40\": 0\.0, &\"f\_rest\_41\": 0\.0, &\"f\_rest\_42\": 0\.0, &\"f\_rest\_43\": 0\.0, &\"f\_rest\_44\": 0\.0, &\"opacity\": 0\.0, &\"scale\_0\": 0\.0, &\"scale\_1\": 0\.0, &\"scale\_2\": 0\.0, &\"rot\_0\": 0\.0, &\"rot\_1\": 0\.0, &\"rot\_2\": 0\.0, &\"rot\_3\": 0\.0 }

lets forget the errors, they have been there for a long time\. The first one is the gltf, the 2nd is the ply thats working
  ],
  [
_splat\_cloud\_data\.gd akkori változata_ \
_ply\_importer\.gd akkori változata_ \
_gsplat\-nodes\.gd akkori változata_ \
Oh dammit, I attached the wrong version of the files\. Here are the correct ones\. My bad :S
  ],
  [
_gltf\_importer\.gd akkori változata_ \
_gaussian\_import\_plugin\.gd akkori változata_ \
_gaussian\_resource\_builder\.gd akkori változata_ \
_compressed\_ply\_decoder\.gd akkori változata_ \
_sog\_decoder\.gd akkori változata_ \
_splat\_decoder\.gd akkori változata_ \
_standard\_ply\_decoder\.gd akkori változata_ \
_binary\_ply\_reader\.gd akkori változata_ \
_gaussian\_resource\.gd akkori változata_ \
Nice, but DO NOT WRITE \"SplatCloudData\" as it won\'t work\. We need to write \"Resource\" there\. \
Now, the next part is, we have another implementation by a chinese guy\. I want to help him by adding this import capability to his code as well in a PR\. I am attaching the current, working import plugin as gltf\_importer\.gd, and I am also attaching the relevant parts of his code\. Please follow his (quite strange) coding style, and create the gltf importer for his code too\.
  ],
  [
okay, this looks fine, I\'d just want to mimic his architecture fully, so please modify gaussian\_import\_plugin\.gd as much as needed, and only create a gltf\_decoder\.gd that is only a ref counted tool script, while the gaussian\_import\_plugin remains the tool editorimportplugin\.
  ],
  [
the gaussian\_import\_plugin\.gd modifications look good, but something got messed up for the gltf\_decoder\.gd, so please rewrite that\.
  ],
  [
okay, it works fine, but I have a question (for both the other and this version) we wrote sh coeff count \= 48 to the top, and I also remember that there were 40 smth sh coefficients for the regular ply files\. However, here I cannot see where they are read into memory\. What is happening?
  ],
  [
oh wait, but I did purposefully look at the loaded gltf models, and they looked as if they had view\-dependent colors\. how could that be,
  ],
  [
okkay\. I will include these sh\-s\. I have one note to myself mostly, since now I don\'t know what to pay attention to if I want to actually see if the code is working or not\. (I\'ll solve this by somehow finding a model that makes it very obvious if sh\'s are applied or not)\. (I now also have to test this on the 2 different codebases\.) I have another question to you tho: since we \'skipped\' an optional extension to the standard, did we skip any other major optional arguments? is there e\.g\. a standardized pbr \-per\-splat data too?
  ],
  [
So, our next goal is to find a modell where it is obvious if the spherical harmonics are working\. Can you look up, which one of the original models demonstrates this the best?
  ],
  [
_gltf\_importer\.gd akkori változata_ \
_splat\_cloud\_data\.gd akkori változata_ \
okay, these descriptions were partially accurate, anyway I found the lego elements of the log of the bonsai good enough to be destinguishable\. Now please implement the SH parsing into this version of the code\. Return the gltf importer to me\.
  ],
  [
_ply\_importer\.gd akkori változata_ \
_gltf\_gs\_ext\_README\.md akkori változata_ \
okay, it got loaded, but the colors are all messed up, it looks like its gay\. are you sure we wouldn\'t need to apply some sort of transformation to the values? I\'ll attach the readme of the gltf extension and our ply reader again\.
  ],
  [
_gltf\_decoder\.gd akkori változata_ \
_standard\_ply\_decoder\.gd akkori változata_ \
_gaussian\_resource\_builder\.gd akkori változata_ \
okay, that was anticlimactic, I tried my best to see the differences between superspl\.at and both my \.ply and \.glb imports, and I kinda think that the ply ones don\'t work either\. Anyway, moving on: let\'s try our best to fix the other import code too: \
please rewrite gltf\_decoder to read the sh\-s too\. I\'ll attach the ply decoder and the builder for reference\.
  ],
  [
ah, this one\'s gay as well :S
  ],
  [
okay, nice! Now lets move back to the other codebase\. The next task will be to have both the godot deferred shading relightable version working, as well as the spherical harmonics one\. Let\'s plan this first before hopping into the code\. The major problem is the memory layout\/data in the GPU\. My lets\-get\-this\-quickly\-over plan is to have both all the spherical harmonic data, as well as the PBR data for every splat, and apply both the sh\-s, and the pbr relighting to all the splat modells\. So a pbr modell will have all 0\-s in the sh\-s, and a non\-relightable model will have some sane defaults for the pbr, or e\.g\. normal\=0,0,0 that tells godot (?) to not apply any more shading\. But I am open to other recommendations\. I don\'t really want to keep 2 separate shaders\/pipelines, nor do I want to blow up all the shaders with macros, which would be the other\/maybe nicer options\.
  ],
  [
_diff\_gltf\.patch akkori változata_ \
_diff\_godotrelightable\.patch akkori változata_ \
okay, sounds fine\. Let\'s plan the whole thing a bit more, I\'ll attach some source files, notably I have the godot reshaded branch, and the gltf import branch which I want to merge\. But it is not a simple git merge\+conflict resolution, since on the reshaded branch we got rid of the spherical harmonics, which were kept (but not really modified) in the gltf branch\. So now I will be sending both diffs containing the modifications of both branches, from the point of their common ancestor\. They contain a lot of modifications, but focus on the important part (shaders, pipeline, importers), and disregard demo\.gd\/tscn, imported binary files, etc\.
  ],
  [
_gltf\_importer\.gd akkori változata_ \
_ply\_importer\.gd akkori változata_ \
Nice, that has worked surprisingly well\. I still would like you to double\-check a few potential modifications: \
1) do we need to touch the ply importer? \
2) do we need to touch the gltf importer? \
3) I want transparency for non\-relighted splats to work as it had worked on the relit branch, can you fix that? \
I am attaching the relevant files\.
  ],
  [
nice, that looks good\. One more extra modification is needed, now both the ply and the glb model with SHs are gay xd
  ],
  [
nice, that indeed worked perfectly\. One more thing to fix while we are here, I don\'t think that has actually ever worked\. The sh\-s look good without rotation, but if I rotate the model (and maybe scale and\/or move?), it breaks, I don\'t think I ever applied the rotation to the spherical harmonics calculations\.
  ],
  [
yup, that was it indeed, it looks totally good now\. One question, how much performance do you think it costs to invert the matrix for every splat? Shouldn\'t we upload the inv model matrices for every model, if we really cared about performance? or is it not worth the complexity in code?
  ],
  [
_enemy\.gd akkori változata_ \
_enemy\_spawner\.gd akkori változata_ \
Hi! Nice, that is finished\. Next, as the last objective before me writing the actual thesis text, I want to use my previous game I made as a demo\. I will be using my version of the plugin, which sadly doesn\'t have instancing, nor real dynamic visibility change\. I want to use the models as the enemies in a TD game\. I want a quick version that works, so we will not overengineer the systems, but we want a slow but stable version that I am able to play through\. Here is the plan: \
we pre\-spawn 10 teddy\-s, which will be infantries \
10 rolling bonsai trees, which will be tanks \
and 21 toyotas, which will be VTBs

This is approx\. the amount of enemies that are on the screen at once\. We should not crash when we exceed these, but also it is not a problem if we can\'t visualize them\. \
For now, we will keep the original, triangle mesh representations of the enemies as well, but I want to place these models on top, to verify the position, spawning and death\. We want to keep the gs models on the map all times (a little below 0,0,0, so they are covered by the ground), and reparent them when a new enemy spawns\. After that enemy die, we tp them back to the group party below 0 (probably we should create a grouping node, so we can reparent them there easily)\. Write a simple error message if we exceed the limit (10, 10 or 21) \
I\'ll attach the enemy and enemy spawner scripts, and tell me if you need anything more\. Maybe we should create a script for the grouping node, so that it can keep track of the available gs instances, and also it can initially spawn them\. I think it is fine to spawn them dynamically, but it is going to lag a lot (it uploads everything to the gpu for every simple visibility\/etc change)\. Also, I will need to raise the 16 model limit to like 48\. I hope I have enough vram\.
  ],
  [
_gaussian\_splatting\_rasterizer\.gd akkori változata_ \
_rendered\_image\.gd akkori változata_ \
_splat\_cloud\_3d\.gd akkori változata_ \
_splat\_cloud\_data\.gd akkori változata_ \
okay, sounds not that bad! I have 2 problems now: \
1) I don\'t actually see the models now, even though they worked when I put one statically in the main scene \
2) I have a humongous hiccup for every reparenting (though no real errors whatsoever), my guess is that we still managed to trigger the whole gpu\-reupload\. I attach some files to confirm\. \
How could we solve the massive hiccups architecturally? does godot\'s reparenting trigger on tree exits and enters? \
We will look into the displaying not actually working afterwards, when I can actually run the thing fine (now it is a 15s hiccup, which is I think roughly the time to upload the stuff to the gpu)
  ],
  [
yup, its starting to take shape, \
1) I\'ll still need to fix the visual alignment (rotation, cutting the table below the bonsai, putting it well on the wheels, etc), but thats on me \
2)
  ],
  [
_gs\_pool\.gd akkori változata_ \
yup, its starting to take shape, \
1) I\'ll still need to fix the visual alignment (rotation, cutting the table below the bonsai, putting it well on the wheels, etc), but thats on me \
2) I\'d want to see the pool in the beginning for debugging purposes: so I actually wanted to put the nodes back to relative 0,0,0 compared to gs pool, and I manually moved gs pool up for now\. They don\'t go back tho, they stay where they died\. The pool works otherwise, they tp to the new pos when a new enemy spawns\. \
3) the cars(vtb) didn\'t spawn at all\. It may be because they are above some kind of limit (vram\/splat count\/something), or it may be that the model or the position of the model is bad\. I\'ll have to fix that too\.

For now I\'d want you to investigate 2)
  ],
  [
nice, that is good! \
One more thing: when it gets in, it also calls queuefree\. we need to handle that too\. its also in enemy\.gd \
for the missing vtbs: \
1) I double checked \
2) I tried putting them in front, so they get spawned first, still I didn\'t see them in the pile \
3) I\'m checking them now with a different model
  ],
  [
nice, I stripped some unnecessary parts of the models and they now look good, and I also see the cars\. Now as a last step I would like to add some model\-dependent transforms, possibly when instantiating, so that they are bigger\/fit better in position to the prev models
  ],
  [
okay, lets not do it like this\. Instead lets add a node3d to enemy, which can be customized in the gui for the descendants, and then the splatcloud it tp\'d to the node3d instead of the root\.
  ],
)
