#page(margin:0pt)[
#image("Gaussian-splatting-integracioja-Godot-Feladatkiiras-1.pdf")
]
// TODO margó tükrözés rendesen, ha 2 oldalasat szeretnék, és ide a feladatkiíráshoz is a megfelelő margó! Illetve a legvégén: jól legyenek párosítva az oldalak, ha tényleg 2 oldalasat csinálok (tartalomjegyzék-tartalomjegyzék, absztrakt-abstract, stb.)
#import "template.typ": template, abstract, appendix

#show: template.with(
  title: "Gaussian splatting integrációja Godot környezetben",
  student: "Vértesaljai Bálint",
  consulent: ("Dr. Vaitkus Márton"),
  //date: datetime(year: 2020, month: 4, day: 1),
  date_format: "[year]. [month]. [day].",
)

#abstract[
  = Kivonat

  TODO
  
  Napjainkban igen komoly fejlődésen mentek keresztül az inverz grafikai módszerek, amelyek
  a képalkotás folyamatát megfordítva végeznek 3D rekonstrukciót képi információk alapján.
  Ezek között kiemelten nagy figyelmet kapott a 3D Gaussian Splatting (3DGS), amely a színteret
  egy speciális, gaussi normális eloszlásokkal kiegészített pontfelhőként reprezentált radiancia
  mező formájában rekonstruálja. Ezen reprezentáció renderelése igen hatékonyan elvégezhető,
  a klasszikus 3D modellek raszterezéséhez hasonló módon. A 3DGS reprezentáció igen széles
  körben kezd elterjedni, már ipari szabványok is kezdenek megjelenni.
  
  Ezen korszerű technológia egy különösen érdekes alkalmazása grafikus assetek előállítása
  számítógépes játékokhoz, pl. a népszerű Godot engine-ben. Ehhez egyrészt szükséges a 3DGS
  reprezentáció integrációja a grafikai és fizikai motorba, másrészt a szokványos 3D modellekkel
  való interakció megvalósítása is.
    
  = Abstract


  TODO
  
  Nowadays, inverse graphics methods have undergone a very serious development, which perform 3D reconstruction based on image information by reversing the process of image creation. Among them, 3D Gaussian Splatting (3DGS) has received a lot of attention, which reconstructs the scene in the form of a radiance field represented as a special point cloud supplemented with Gaussian normal distributions. The rendering of this representation can be performed very efficiently, in a way similar to the rasterization of classical 3D models. 3DGS representation is becoming very widespread, and industry standards are already starting to appear.
  
  A particularly interesting application of this modern technology is the production of graphic assets for computer games, e.g. in the popular Godot engine. This requires, on the one hand, the integration of the 3DGS representation into the graphics and physics engine, and on the other hand, the implementation of interaction with conventional 3D models.
]






= Bevezetés

Valahova a féléves beosztásokat: mi volt önlab1, mi dipterv1, mi dipterv2

Dipterv referencia: @diplomaterv

== Inverz renderelés

== Gaussian Splatting

== Godot

== Gaussian Splatting a Godot-ban

== Motiváció

== A diplomaterv további szerkezete


= Irodalomkutatás

== Gaussian Splatting témájú cikkek

=== Eredeti cikk

Referencia: @kerbl-2023-3dgs

=== Relightolhatóság

=== Időbeliség

=== Szabványos GLTF formátum

blogpost: @gltf-szabvany

=== Egyéb cikkek, ...

Gen AI, inverz módszerek EA diáiról jó referenciák: @genai-inverzrendering-ea

nerf, ilyesmi, megemlítése

== Más játékmotorok, Gaussian Splatting integrációjuk

Unity, Unreal, stb. hogy áll? Vannak pluginok? Miért a Godot?

== Gaussian Splatting implementációk Godot-ban

=== Retr0 valami (GodotGaussianSplatting)

=== A másik, amelyik nemigen ment jól

=== A kínai csávóé

amelyik aközben jelent meg, miközben írtam a diplomatervet

fontos az alkalmazkodóképesség, és a kollaboráció, azt véltem megfelelő megoldásnak, hogyha összedolgozunk, és merge-eljük a projekteket

== Választott módszer, technológia



= Tervezés

== Fájlformátumok bemutatása

=== Ply

==== Sima, gömbi harmonikusos

==== Relightolható

=== Splat

=== GLTF

== Mesh2Splat

citation ott van a githubjukon

=== Linuxon futtatás PR-ja

végül egy másikat mergeeltek

== Godot bővíthetősége, lehetőségek

=== Megjelenítés FSQuad-ként

=== Megjelenítés compositor effect-tel

== Követelmények

=== Funkcionális

=== Nem funkcionális

== Architektúra

Milyen osztályok vannak, mik singleton/autoload-ok, milyen shaderek hívódnak meg, és ezeknek mik a felelősségi körei

= Önálló munka bemutatása

Hogy érdemes taglalni? Lehet időrendben (problémák felmerülésének, logikus megoldásának sorrendjében)? Vagy témánként (pl ha időben két külön helyen jött elő a dinamikus láthatóságváltoztatás, akkor azt vonjam össze)? Vagy fájlonként?

== A GDScript nyelv

== A GLSL nyelv

== Részek (??) bemutatása

=== GDScript oldali rész

=== Shaderek


== Önlab 1 alatt végzett megoldás felvázolása

Az önlab 1-es GitHub repository-m itt @onlab-github-repo érhető el, a kóddal és a dokumentációval együtt.

Adott a megtekintő program, amely be tud tölteni egy `.ply` kiterjesztésű splat-os modellt, és meg tudja azt jeleníteni a játékmotor keretein belül. Illetve adott példaként az autó-szimuláló program. Adottak továbbá splat-os modellek, amiket lehet használni.

Ennek megfelelően a féléves munka a következő részegységekre osztható:

- Megjeleníteni egyszerre több pontfelhőt
- Ezeket a pontfelhőket függetlenül mozgatni
- Feltölteni pontfelhőnként transzformációs mátrixokat, hogy tetszőlegesen mozoghassanak a modellek
- Ezeket a transzformációkat megfelelően feltölteni minden képkockában, lehetőleg automatizált módon megtalálva a hozzájuk tartozó játékobjektumot, ahonnan a transzformáció származik
- Mélységhelyesen összekombinálni a pontfelhős, és a sima modelleket
- Összevonni a két projektet (gsplat-os, illetve az autós)
- Robusztusabbá tenni a `.ply` fájl-beolvasást, hogy a `.splat`-ból [SuperSplat](https://superspl.at/editor)-tal konvertált `.ply` fájlokat is képes legyen beolvasni
- Javítani felmerülő problémákat
    - Stuttering: camera és transzformációs mátrix feltöltésének a process priority állítása lett a megoldás
    - Artifactos mélység: a shader kód párhuzamosan tölt be adatokat, és dolgozza fel őket, ehhez viszont szükséges shared bufferek használata

=== Egyszerre több pontfelhő

A megjelenítő egy pontfelhő megjelenítésére volt felkészítve, nekünk viszont egy játékban jórészt több pontfelhőt is célszerű megjeleníteni: például az autó teste és a 4 kereke már eleve 5 külön objektum. Ehhez azt találtam ki, hogy a CPU-n összeuniózom a pontfelhőket, az adataikat, viszont elmentem azt is, hogy mely indexeknél vannak a határok. Ezután a GPU-ra feltöltéskor kihasználok egy float-ot, ami eddig padding célt szolgált, és minden feltöltött splat esetén egy ID-t is továbbítok, ami megmondja, hogy hányadik objektumhoz tartozik.

```py
class_name PlyFile extends Resource

var size : int
var vertices : PackedFloat32Array
var properties : Array[StringName]
var split : Array[int] # indices where new objects start

...

static func merge(pc1 : PlyFile, pc2 : PlyFile) -> PlyFile:
	var merged := PlyFile.new()
	merged.size = pc1.size + pc2.size
	assert(pc1.properties.hash() == pc2.properties.hash())
	merged.properties = pc1.properties
	merged.vertices = PackedFloat32Array(pc1.vertices)
	merged.vertices.append_array(pc2.vertices)
	merged.split.append_array(pc1.split)
	merged.split.append(pc1.vertices.size())
	for s in pc2.split:
		merged.split.append(s + pc1.vertices.size())
	return merged

...

static func load_gaussian_splats(point_cloud : PlyFile, stride : int, 
    device : RenderingDevice, buffer : RID, should_terminate_reference : Array[bool], 
    num_points_loaded : Array[int], callback : Callable):
...
			### Opacity 
			points[b+6+4] = 1.0 / (1.0 + exp(-p[v+54]))
			
			### ID for differenciating between objects 
			points[b+11] = 0
			for k in point_cloud.split:
				if v >= k:
					points[b+11] += 1
...
```

=== Pontfelhők transzformációja

Miután a GPU-n már lehet tudni, hogy melyik splat melyik objektumhoz tartozik, így lehetséges objektumonként más transzformációt alkalmazni a splatokra. Ehhez létre kellett hozni, és fel kell tölteni egy új uniform buffert:
```py
const MAX_OBJECT_COUNT := 16 # number of gsplat object transforms, same as in gsplat_projection.glsl
var object_transforms : Array[Transform3D]
...

	descriptors['transforms'] = context.create_uniform_buffer(16*MAX_OBJECT_COUNT*4)

...

	context.device.buffer_update(descriptors['transforms'].rid, 
        0, 16*MAX_OBJECT_COUNT*4, get_transforms())

...

func update_object_transforms(transforms: Array[Transform3D]) -> void:
	object_transforms = transforms

func get_transforms() -> PackedByteArray:
	var fbuf := PackedFloat32Array()
	assert(len(object_transforms) <= MAX_OBJECT_COUNT)
	var t := []
	for i in object_transforms:
		t.append(Projection(i))
	for i in (MAX_OBJECT_COUNT - len(object_transforms)):
		t.append(Projection.IDENTITY)
	for i in MAX_OBJECT_COUNT:
		fbuf.append_array([	t[i].x[0], t[i].x[1], -t[i].x[2], -t[i].x[3],
							t[i].y[0], t[i].y[1], -t[i].y[2], -t[i].y[3],
							-t[i].z[0], -t[i].z[1], t[i].z[2], t[i].z[3],
							-t[i].w[0], -t[i].w[1], t[i].w[2], t[i].w[3]])
	var bytebuf := PackedByteArray()
	bytebuf.resize(4 * fbuf.size())
	bytebuf.fill(0)
	for i in range(len(fbuf)):
		bytebuf.encode_float(i*4, fbuf[i])
	return bytebuf
```

Amit pedig a shaderben fel tudunk használni:

```glsl
// same as in gaussian_splatting_rasterizer.gd
#define MAX_OBJECT_COUNT 16

...

struct Splat {
	vec3 position;
	float time;
	float covariance[6]; // Contains top triangle of symmetric matrix
	float opacity;
	float id;
	float sh_coefficients[16*3]; // Spherical harmonic coefficients in increasing order
};

...

layout (std140, set = 0, binding = 7) restrict uniform Transforms {
	mat4 transforms[MAX_OBJECT_COUNT];
};

...

	// --- FRUSTUM CULLING ---
	vec3 splat_pos = splat.position*model_scale;
	vec4 view_pos = view_matrix * transforms[int(splat.id + 0.5)] * vec4(splat_pos, 1.0);
	vec4 clip_pos = projection_matrix * view_pos;
	
	...
	
	mat3 curr_transform = mat3(transforms[int(splat.id + 0.5)]);
	mat3 cov_mx = curr_transform * DECODE_COVARIANCE(splat.covariance) * transpose(curr_transform);
	const vec3 covariance = project_covariance(cov_mx, splat_scale, view_pos.xyz, dims);
	
...
```

=== Automata objektum-megtalálás

Jelenleg nem támogatott új objektumok létrehozása illetve eltüntetése, láthatóvá illetve láthatatlanná tétele futásidőben. Támogatott viszont az, hogy egy, a Godot Node-ok között is megtalálható objektumot a SceneTree-hez hozzáadva automatán be legyen töltve a splat-os objektum, és a megfelelő Node transzformációja legyen rá hattatva, figyelembe véve a szülő node-ok transzformációját is, így lehetséges valós időben mozgatni, transzformálni őket ugyanúgy, mint a sima modelleket.

A következő script a `class_name` segítségével meg fog jelenni az editorban, mint hozzáadható Node, és lesz egy állítható paramétere, a `ply_file`. Ide be lehet állítani a megfelelő path-t.

```py
class_name SplatMesh extends Node3D

@export var ply_file: String

func is_splat_mesh():
	pass
```

Ezután a gyökérnode induláskor összeszedi az objektumokat, és eltárolja őket, hogy a transzformációikat el tudja küldeni:

```py
var splat_meshes : Array[SplatMesh] = []

func _ready() -> void:
	find_by_method(self, StringName("is_splat_mesh"), splat_meshes)
	assert(len(splat_meshes) <= GaussianSplattingRasterizer.MAX_OBJECT_COUNT)
	var splat_filenames := []
	for m in splat_meshes:
		splat_filenames.append(m.ply_file)
	
	init_rasterizer(splat_filenames)
    ...

# source: https://forum.godotengine.org/t/how-do-you-get-all-nodes-of-a-certain-class/9143
func find_by_method(node: Node, method_name : StringName, result : Array) -> void:
	if node.has_method(method_name) and node.is_visible_in_tree():
		result.push_back(node)
	for child in node.get_children():
		find_by_method(child, method_name, result)
```

Az összeszedéshez biztosan van jobb módszer, mint a tagfüggvénynév alapján való keresés, de én limitált keresés során nem találtam, és ez működik. Típuslekérdezés csak beépített típusokra ad eltérő eredményt.

```py
func _process(delta: float) -> void:
    ...
	var splat_transforms : Array[Transform3D] = []
	for m in splat_meshes:
		splat_transforms.append(m.global_transform)
	rasterizer.update_object_transforms(splat_transforms)
```

Fontos megemlíteni a szálakat, ugyanis a rasterizer függvényeit alapvetően a render thread-en hívjuk, ez az objektum-transzformációk feltöltése viszont, a kameratranszformációk lekérdezéséhez hasonlóan a "sima" thread-en történik.

=== Mélységhelyes összekombinálás

Ahhoz, hogy a képen össze lehessen fésülni a pontfelhős, és a sima megjelenítést, amelyek teljesen külön pipeline-on futnak, szükséges a pontfelhős megjelenítésnél is, a végső renderelt képen egy pixelenkénti mélységérték szerzése. Ennek segítségével legalább pixelenként el lehet dönteni, hogy a két renderelt kép közül melyik nyerjen. A sima pipeline-nál már eléri a játékmotor a mélységet, nekünk a splat-os megjelenítésnél kell ezt elérhetővé tennünk:

Projection:

```glsl
	data.pos_z = (ndc_pos.z + 1.0)*0.5;
```

Render:

```glsl
shared float[WORKGROUP_SIZE] pos_z_tile;

...

    for (uint i = 0; i < num_iterations && shared_t > MIN_FACTOR; ++i) {
    ...
        for (uint j = 0; j < chunk_size && t > MIN_ALPHA; ++j) {
            ...
            float pos_z = pos_z_tile[j];
            ...
            if (alpha > 0.2) {
                weighted_depth += (1.0 - pos_z) * alpha * t;
                total_weight += alpha * t;
            }
            ...
            t *= (1.0 - alpha);
        }
        ...
    }
    vec3 heatmap_color = mix(vec3(0,0,1), vec3(1,0.2,0.2), num_splats*5e-4) * (1.0 - t) * heatmap_factor;
    float final_depth = total_weight > 0.0 ? (weighted_depth / total_weight) : 0.0;
	imageStore(rasterized_image, ivec2(image_pos), vec4(blended_color + heatmap_color, final_depth));
	...
```

Main spatial shader:

```glsl
void fragment() {
	ALBEDO = srgb_to_linear(texture(render_texture, SCREEN_UV).rgb);
	DEPTH = texture(render_texture, SCREEN_UV).a;
}
```

=== Projektek kombinálása

A splat-os és az autós Godot projektek összefésülése egészen könnyen ment, a fájlok összemásolásán túl a `project.godot` fájlt kellett kompatibilissá tenni mindkét projekt részére, többek között a definiált (billentyűzet) bemenetet, és a globális scripteknek megfelelő scripteket (autoload) kellett átemelni. Szerencsére a `project.godot` egy szöveges fájlformátum, sima config fájlként viselkedik, így akár kézzel is könnyű volt az egyes bejegyzéseket átemelni, a maradék beállítást pedig könnyen megtaláltam az editorban.

Továbbá mindkét projektben volt az alapértelmezett jelenet, aminek a node-jaihoz a szükséges scriptek hozzá voltak adva. Kis logikázás után úgy láttam, hogy a splat-os projekt gyökérnode-ja kell, hogy maradjon, többek között azért is, hogy a hozzáadott SplatMesh-eket megtalálja a jelenetben. Nem volt különösebb gond az autós projekttel, ha annak a gyökérnode-ját a splat-os projekt gyökérnode-ja gyerekeként tettem be.

Ami következményként nehézséget okozott, az a stuttering kiküszöbölése, amit az okozott, hogy az autós projektben a kamerát egy script állította, míg a splatos projektben ugyanezen (aktív) kamera transzformációját egy script továbbította a GPU-nak, és ez a két script valamiért nem meghatározott sorrendben futott. A process priority állításával a probléma megoldódott.

=== Adatok beolvasása

A bemeneti adatformátum a `.ply`, illetve ennek egy speciális esete. Eredetileg a megjelenítő projekt csak olyan modelleket tudott megjeleníteni, amiknek a 62 property-je mind szerepel, és egy konkrét sorrendben van:

```x, y, z, nx, ny, nz, f_dc_0, f_dc_1, f_dc_2, f_rest_0, f_rest_1, f_rest_2, f_rest_3, f_rest_4, f_rest_5, f_rest_6, f_rest_7, f_rest_8, f_rest_9, f_rest_10, f_rest_11, f_rest_12, f_rest_13, f_rest_14, f_rest_15, f_rest_16, f_rest_17, f_rest_18, f_rest_19, f_rest_20, f_rest_21, f_rest_22, f_rest_23, f_rest_24, f_rest_25, f_rest_26, f_rest_27, f_rest_28, f_rest_29, f_rest_30, f_rest_31, f_rest_32, f_rest_33, f_rest_34, f_rest_35, f_rest_36, f_rest_37, f_rest_38, f_rest_39, f_rest_40, f_rest_41, f_rest_42, f_rest_43, f_rest_44, opacity, scale_0, scale_1, scale_2, rot_0, rot_1, rot_2, rot_3```

Ez akkor ütközött problémába, amikor egy másik forrásból származó modellt szerettem volna megjeleníteni, ami `.splat` formátumban volt. Addig nem probléma, hogy az online [Supersplat](https://superspl.at/editor) segítségével át lehet konvertálni ezt `.ply` fájllá, viszont ebből a modellből hiányoztak bizonyos property-k, 14 volt összesen, és a meglevők sem megfelelő sorrendben voltak:

```x, y, z, opacity, rot_0, rot_1, rot_2, rot_3, f_dc_0, f_dc_1, f_dc_2, scale_0, scale_1, scale_2```

Így módosítottam a beolvasó részt, hogy 0-ként olvassa a hiányzó adatokat, illetve a megfelelő pozícióba tegye a property-ket. Ez azért működik, mert ami hiányzik, az a 45 db spherical harmonikusokhoz szükséges érték, amiket lehet 0-ra inicializálni, illetve a normálvektor, amit pedig nem használ fel a beolvasó.

```py
func parse(path : String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	var line := file.get_line().split(' ')
	while not line[0] == 'end_header':
		line = file.get_line().split(' ')
		match line[0]:
			'format':   file.big_endian = line[1] == 'binary_big_endian'
			'element':  size = int(line[2])
			'property': properties.push_back(line[2])
	vertices = file.get_buffer(size*len(properties) * 4).to_float32_array()
	if properties.hash() != DEFAULT_PROPERTIES.hash():
		var prop_inverse := {}
		for i in properties.size():
			prop_inverse[properties[i]] = i
		var new_vertices := PackedFloat32Array()
		new_vertices.resize(size*DEFAULT_PROP_CNT)
		for i in size:
			for pi in DEFAULT_PROP_CNT:
				new_vertices[i * DEFAULT_PROP_CNT + pi] = 
                    vertices[i * len(properties) + prop_inverse[DEFAULT_PROPERTIES[pi]]] 
                    if DEFAULT_PROPERTIES[pi] in prop_inverse else 0
		properties = DEFAULT_PROPERTIES.duplicate()
		vertices = new_vertices
```

== Dipterv 1 alatt végzett megoldás felvázolása

=== RenderedImage pull vs SplatMesh push

dinamikus láthatóság-változtatás, még nem a legjobb módon

=== Elsőosztályú polgárok

Ikonok, betöltés, export már elvileg működne belenyúlás nélkül, editor kezeli az importot

=== AMD Bug

vkradixsort-nál is felmerült, és javították közben, de az új verzió nem lett betéve a mi általunk használt könyvtárba

=== CompositorEffect-re áttérés

=== Másik addon-ra rebase-elés

Olyan feature-ök, amik jobbak voltak, átültetése

=== Igazi dinamikus láthatóság

=== Instancing

=== Relightolhatóság

==== Saját fényszámítással

==== A Godot fényszámításával


== Kitérő: Typst

A diplomaterv dokumentumának elkészítéséhez a Typst nevű nyelvet használom, ami egy modern LaTeX megfelelő. Dani nevű szobatársam segítségével konvertáltuk a sablonokat (főleg ő), ez elérhető itt: @typst-bme-dipterv-sablon

=== Rövid bemutatás

open source, cég háttere, szintaktika, elterjedés

=== Miért jobb

word/libreoffice-nál, latexnél

Word:
kód blokkok, számozás, képek számozása (?), bibliography beszúró GUI izébizénél sokkal egyszerűbb, stb

LaTeX:
20 package a fordításhoz, hosszú build time, csúnya szintaktika, végtelen mennyiségű fájl amik elég nehezen átláthatók, fordításkor is teleszemeteli a dolgot

= Önálló munka értékelése, eredmények


== When Hamsters Attack TD

játék bemutatása, integrációja a pluginnal, mint példa felhasználás
@when-hamsters-attack-td

== Tanszék modelljének példafelhasználása

mire? Legyen valami kis konkrét demo belőle? Itt lehetne demozni, ha a háttér GSplates, míg a WhenHamstersAttackTD-nél, ha a karakterek GSplatesek

== Asset library plugin

Felkerül végre??

== Instancing mérése felhasznált memóriával

== Még mit lehetne értékelésnek, eredménynek?

<tovabbiteendok-dipterv2>
== További teendők a Dipterv 2-ig (végleges doksiig)

- Relightolható branch (a saját relightolásos) működjön a nem relightolt dolgokkal egyszerre, ennek visszamerge-elése a mainbe, esetleg PR a kínai csávónak (ha nyitott rá)
- GLTF szabvány implementálása, tesztelés vele
- a WhenHamstersAttackTD @when-hamsters-attack-td játék átírása félig (vagy teljesen) GSplatos modellek használatára (esetleg tanszéki terem mint background?, vagy azzal is egy példafelhasználás?)
- ezen dokumentum finomítása, véglegesítése
  - irodalomjegyzék vs lábjegyzet? Melyiket mennyire? Mind mehet irodalomjegyzékbe, nem baj ha nagyon sok?

== TODO a dipterv1 doksi leadásáig!

- kódblokkok számozása az önlabos doksi szövegében
- pár oldalt írni az ebben a félévben végzett munkáról
  - ehhez pedig számozott képeket beszúrni, kipróbálni a számozást fejezetek között is (melyik számozás legyen? - ennek eldöntése, formázással bajlódás majd ráér később)
  - képaláírások, kép forrásának jelölése hogyan?
- referenciák a képekre, kódblokkokra, más fejezetekre a doksin belül
- bemutató diasor
  - előző diasorból kiindulva, 1-2 diát megtartva
  - a félév során elvégzett lépések, munkák 1-1 dián
  - typst egy dián, sablonról, elkészített dokumentációról szót ejteni
  - utsó dián a @tovabbiteendok-dipterv2 -nél taglaltak felsorolása, konzultálni ezekről a konzulenssel, időpontot kérni ezen dokumentum átnézésére, és finomítására
  - további dolgok időbeosztása a nyáron, konzultációk hogyan, ilyesmi 
  
= Összefoglaló

Sokat tanultunk a dipterv alatt, megismerkedtünk ezzel, azzal, godot rendering pipeline, gaussian splatting, fájlformátumok, typst, stb

a plugin használható, viszonylag jó integrációval, fenn van (??) az asset store-ban, hozzátettem bizonyos fejlesztéseket, mások meg itt és itt érhetők el, ... (külön asset store item a relightolható mesh-esnek??, ha nem merge-eli majd?)

#bibliography("bibliography.yml")

#show: appendix

AI nyilatkozat majd ide!

= Még több lorem
#lorem(200)

== Na még egy kicsi
#lorem(40)

// vim:spelllang=hu:spell
