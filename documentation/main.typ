#page(margin:0pt)[
#image("Gaussian-splatting-integracioja-Godot-Feladatkiiras-1.pdf")
]
#import "template.typ": template, abstract, appendix

#show: template.with(
  title: "Gaussian splatting integrációja Godot környezetben",
  student: "Vértesaljai Bálint",
  consulent: ("Dr. Vaitkus Márton"),
  date: datetime(year: 2026, month: 12, day: 10),
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

== Számítógépes grafika

A számítógépes grafika gyűjtőfogalom alá tartozik mindenféle olyan technológia, amely a számítógép képernyőjén 2D, illetve 3D modelleket képes megjeleníteni, alakzatokat, jeleneteket képes kirajzolni. #footnote[https://en.wikipedia.org/wiki/Computer_graphics_(computer_science)] Ezek a játékipartól kezdve az orvosi képalkotásig sok helyen felhasználásra kerülnek. Erősen kapcsolódó területek még a gépi látás, amikor a számítógép a kész képet értelmezi, a 3D modellek manipulációja, illetve többek között a mesterséges intelligencia modellekre, képekre történő alkalmazása is.

== Inverz renderelés

Inverz renderelésnek azt a módszert nevezzük, amikor már kész képekből állítunk elő 3D modelleket. Tulajdonképpen megpróbáljuk rekonstruálni, milyen alakzat volt ott. @genai-inverzrendering-ea Ezek a kész képek lehetnek például egy adott objektumról készült fotók sok, különböző szögből, vagy egy beltér körbevideózva. Ez a rekonstrukció egy bonyolult folyamat, és sokféle módszer létezik rá. A különböző inverz renderelési módszerek napjaink egyik erősen kutatott témáját teszik ki. @kerbl-2023-3dgs

== Gaussian Splatting

A Gaussian Splatting egy inverz rendering módszer, aminél a jelenetet Gauss-i eloszlású átlátszósággal rendelkező 3D foltokkal próbáljuk a lehető legjobban leírni @kerbl-2023-3dgs. Képekből előállítani a 3D modellt elég erőforrásigényes, viszont a modellek megjelenítése megfelelő minőség esetén kifejezetten közeli tud lenni a valósághoz. Nagy előnye, hogy a megjelenítőt sima, standard grafikus csővezetékkel is lehetséges implementálni, és valós időben, 100-as nagyságrendű FPS-sel renderelhető.

Az @gaussian_splatting_example_image. ábrán látható egy autó Gaussian Splatting alapon megjelenítve, a kép bal oldala jó minőségben, míg a kép jobb oldala olyan módon, hogy az egyedi, Gauss-i eloszlású 3D foltok külön-külön látsszanak. A kép a feladatkiírásból származik.


#figure(
  image("pictures/gaussian_splatting_example_image.png")
  , caption: [A Gaussian Splatting szemléltetése egy autó modellel]
) <gaussian_splatting_example_image>


== Godot

A Godot Engine #footnote[https://godotengine.org/] egy szabad és nyílt forráskódú játékmotor, és az elmúlt években jelentős növekedésnek örvendett. #footnote[https://gameworldobserver.com/2026/07/29/unity-is-no-longer-the-leader-godot-has-become-the-most-popular-engine-at-gmtk-game-jam-2026] Megtalálhatóak benne a legfontosabb eszközök egy játék fejlesztéséhez, viszont a teljes motor az ellenfeleihez képest egy nagyon könnyű, lightweight megvalósítással rendelkezik: a motor egyetlen futtatható fájl elindításával használható, installációt nem igényel, és a teljes mérete 200MB alatt van. Így indításkor, és használat közben is, alap feladatok esetén legalábbis sokkal gyorsabb.

A 4-es fő verzióban a következő generációs renderer Vulkan alapú, és ennek bővítésére, illetve a Vulkan-hoz történő viszonylag alacsony szintű hozzáférésre is különféle lehetőségeket nyújt, még a beépített scriptnyelvből is.

== Gaussian Splatting a Godot-ban

A Godot rendererjei, architektúrája alapértelmezetten a szokványos, háromszöghálós modellek megjelenítésére van optimalizálva, a Gaussian Splatting nincs a hivatalosan támogatott feature-ök között. Harmadik féltől származó Gaussian Splatting megjelenítők, pluginok viszont folyamatosan jelennek meg az interneten, ezeket a @gsplat-in-godot fejezetben részletezem.

== Motiváció

A motorba történő megfelelő integráció esetén lehetőség lenne Gaussian Splatting modelleket rendes, háromszöghálós modellekkel együtt megjeleníteni, a háromszöghálós modellekhez hasonlóan a 3D térben transzformálni, és ezekkel akár demókat, prototípusokat, illetve eszközöket, játékokat készíteni.

== A diplomaterv további szerkezete

A továbbiakban bemutatom a témában megtalálható forrásokat, implementációkat, és leírom az általam elvégzett munka tervét, majd a megvalósítását, és a megvalósítás felhasználását. Végül összegzem a leírtakat. TODO picit bővebben kifejteni

= Irodalomkutatás

== Gaussian Splatting témájú cikkek

=== 3D Gaussian Splatting for Real-Time Radiance Field Rendering

A Gaussian Splatting (GS) technológiát az @kerbl-2023-3dgs cikk vezette be, ami ezután felkapott téma lett. A szerzők többek között különböző Neural radiance field (NeRF) #footnote[https://en.wikipedia.org/wiki/Neural_radiance_field] implementációkhoz hasonlították a saját implementációjukat, túlszárnyalva azokat pontosságban, és valósidejű megjelenítésben. Az általuk készített megoldás nem csak megjelenítést tartalmaz, hanem a képekből történő paraméteroptimalizációt is, ami a GS modelleket, pontfelhők paramétereit állítja elő.

=== Relightolhatóság

<relightolhatosag-bemutatas-fejezet>

Az eredeti cikk nézetiránytól függő színeket lehetővé tett a kiterjedt pontoknak, viszont ezek beégetett színek, azaz egy adott modell egy adott irányból mindig ugyanúgy fog kinézni, fényektől függetlenül. Ez egy teljes 3D jelenet rekonstrukciójánál egy teljesen jó eredményt adó megoldás, viszont egy-egy különálló, dinamikus transzformációval rendelkező modell esetén nem mindig ad az elvártnak megfelelő eredményt. Ez különösen fontos lehet egy játékmotor esetén, ahol általában fények is vannak egy jelenetben, és a GS modell nem odaillőnek tűnhet, ha nem reagál a fényekre az elvárt módon.

Ennek megoldására többféle lehetőség van, más-más előnyökkel és hátrányokkal. A @scolari2025mesh2splat forrásban megjelölt program segít bizonyos fajta, újravilágítható pontfelhőket generálni háromszöghálós modellekből, ennek a fájlformátumnak a részletezése a @religtholhato-ply-format fejezetben található. Ezen kívül a @kinai-repo implementációban is található újravilágítás opció, ami jelentősen különbözik a fentebbi fájlformátum alkalmazásától.

=== Időbeliség

Külön izgalmas feladat, ha időben is változik a felvett jelenet, ilyenkor a pontfelhő időbeli transzformációját is el lehet tárolni, és ugyanazt a mozgó jelenetet akár több szemszögből, vagy mozgó szemszögből visszajátszani. Különböző pontfelhők utólagos szerkesztésére is lehetőség van. Erről szól a @4dgs-wu-time cikk.

=== Szabványos GLTF formátum

A Gaussian Splatting modelleket valamilyen módon el kell tárolni. Erre sokféle megoldás született: különféle kulcsszavakkal rendelkező `.ply` fájlok, `.splat` fájlok, és egyéb fájformátumok is használatban vannak. Ezek részletesebb bemutatása a @fajlformatumok-fejezet. fejezetben szerepel. 2026 februárjában jött ki a témában egy GLTF-kiterjesztés szabvány @gltf-szabvany is, amit a Khronos Group kezel. Ennek előnye, hogy pontszerű pontok halmazaként a GS megjelenítést nem támogató programok is meg képesek jeleníteni a modelleket, a visszafelé kompatibilitás miatt. Ennek a szabványnak az implementálása a feladatkiírásomban is szerepel.

=== Generatív AI és inverz módszerek a képszintézisben

A témában jól összegyűjtött információk forrása lehet többek között a Budapesti Műszaki és Gazdaságtudományi Egyetemen Dr. Vaitkus Márton által nemrég indított szabadon választható, Generatív AI és inverz módszerek a képszintézisben című tárgy honlapja és diasorai, amik a @genai-inverzrendering-ea forrásnál érhetőek el.

== Gaussian Splatting integrációk más játékmotorokban

Gaussian Splatting implementációk a főbb játékmotorok mindegyikénél megjelent #footnote[https://www.polyvia3d.com/guides/gaussian-splatting-unity-unreal].

=== Unity

Nem található a Unity-hoz hivatalos GS támogatás, vagy hivatalos plugin. Található viszont több, harmadik fél által készített plugin: a UnityGaussianSplatting #footnote[https://github.com/aras-p/UnityGaussianSplatting/tree/main] kimondottan széles körben használt a csillagok mennyisége alapján, míg a gsplat-unity #footnote[https://github.com/wuyize25/gsplat-unity] frissebb, és szintén az előző kódbázison alapszik.

=== Unreal Engine

Unreal esetén sem találtam hivatalos, Epic által ösztönzött megvalósítást, található viszont ugyanúgy többféle harmadik fél által implementált megjelenítő. A Luma UE Plugin #footnote[https://lumaai.notion.site/Luma-Unreal-Engine-Plugin-0-41-8005919d93444c008982346185e933a1] és az XScene-UEPlugin #footnote[https://github.com/xverse-engine/XScene-UEPlugin/tree/main/UEPlugin] is egy szélesebb ökoszisztéma részeként jelenik meg, míg az unreal-splat #footnote[https://github.com/JI20/unreal-splat] egy fapados, egyszerű implementáció benyomását kelti.

== Gaussian Splatting implementációk Godot-ban
<gsplat-in-godot>

A Gaussian Splatting integráció minden népszerű játékmotornál egy releváns feladat. Én a témaválasztásnál a Godot Engine mellett döntöttem, mivel ez a motor áll hozzám a legközelebb, a szabad és nyílt forráskódú megvalósításával, és a könnyűségével, bloat-mentességével.

Mivel a motor, és a Gaussian Splatting téma is népszerű, ezért több, hasonló témájú implementáció is található, és a projektem lefolyása során folyamatosan jelennek meg az újabb megvalósítások. Külön feladat az ezen projektek felfedezése, és releváns esetben a kapcsolatfelvétel, kollaboráció.

=== GodotGaussianSplatting 2Retr0-tól
<OriginalGGSVFejezet>

2Retr0 GS megjelenítője @OriginalGodotGaussianSplattingViewer az eredetileg leginkább használt implementáció. Ez egy darab GS modellt képes Godot-ban megjeleníteni, és egy repülő kamerával lehet körüljárni a modellt. Az @originalggs_banana. képen látható egy példakép, ami egy banánt ábrázol, az alatta levő terítővel együtt.

#figure(
  image("pictures/originalggs_banana.png")
  , caption: [A GodotGaussianSplatting megjelenítő megjelenít egy banánt]
) <originalggs_banana>


=== godot-gaussian-splatting haztro-tól

Egy másik implementáció haztro-tól származik @MasikGodotGaussianSplattingViewer, amelyik viszont a projekt kezdetekor történő kipróbáláskor alulmaradt a @OriginalGGSVFejezet. fejezetben taglalt implementációtól. 2026-ban viszont további fejlesztéseket hajtottak rajta végre, ami a másik megjelenítőről nem mondható el.

=== godot-gaussian-splatting ReconWorldLab-tól

<kinai-repo-fejezet>

Ez az implementáció @kinai-repo már a diplomaterv írása közben bukkant fel. Ez már, az előzőekkel szemben, képes több modellt megjeleníteni, és transzformációt alkalmazni rájuk. Ez az plugin a @OriginalGGSVFejezet. fejezetben bemutatott implementáción alapul. Az idő előrehaladtával több, előrehaladott fejlesztést is elvégzett a készítő: többek között többféle renderer támogatása, újravilágítás, és collision generálás.

=== godotGS klausi3D-től

<godotgs-fejezet>

Ez @klausi-godotgs egy szintén újonnan, 2026-ban feltűnt implementáció. Az architektúra viszont más, mint a fentebbieknél: ez a megvalósítás a teljes játékmotort forkolta, és kifejezetten nagy mennyiségű munka látható a repository-ban: több 100-as nagyságrendű issue-k, commit-ok és deployment-ek. Mindez annak ellenére, hogy az egyetlen contributor látható, és egyetlen csillaggal rendelkezik a repository. A sok befektetett energia a használatkor is érződik, például az extenzív mennyiségű debug információn, illetve az elérhető opciók, változtatható paraméterek számán is.

Ez a projekt kívülről meglehetősen AI-first projektnek tűnik, és az egyetlen ember által AI segítségével ennyi idő alatt elvégzett minőségi munka mennyisége elgondolkozásra, és kíváncsiságra késztet a szakma jövőjével kapcsolatban.

== Választott módszer
<valasztott-modszer-fejezet>

Mivel a projekt kezdetekor a @kinai-repo-fejezet. és a @godotgs-fejezet. fejezetben leírt projektek még nem léteztek, ezért a választott módszer a @OriginalGGSVFejezet\-ben leírt projekt kibővítése úgy, hogy a feladatkiírásban szereplő integrációs problémák megoldásra kerüljenek.

Eközben, amint felbukkant a @kinai-repo-fejezet. fejezetben leírt projekt, kollaborációt kezdeményeztem @kollaboracio-kezdemenyezese, amelyet a másik fél elfogadott. Ezt megkönnyítette, hogy mindketten a @OriginalGGSVFejezet\-beli kódbázisból indultunk ki, így sok része a kódnak megegyezett. Némely fejlesztéseket én végeztem el, némelyeket ő, melyeket többé-kevésbé átvettünk egymástól. Ezt könnyen lehetővé tette az, hogy mindhárom kódbázis MIT licensszel rendelkezik, így lényegében a licensz és a copyright bemásolásával bármelyik kódot bárki felhasználhatja, még akár zárt forráskódú projektben is #footnote[https://en.wikipedia.org/wiki/MIT_License]. Így például a feladatkiírásban szereplő feladatok megoldásával is, több Pull Request-et készítettem neki. Ezeket az elvégzett munkákat, és kollaborációkat az @onallo-munka-bemutatasa. nagyfejezetben részletezem.

= Technológiák bemutatása

A tervek és az önálló munka bemutatásához szükséges először a technológiai hátteret bemutatni. Ide tartoznak a pontfelhők lehetséges tárolási formátumai, a pontfelhőket manipulálni képes programok, illetve a Godot-ban szereplő programozási környezet.

== Fájlformátumok
<fajlformatumok-fejezet>

Ahhoz, hogy a pontfelhőket sorosítani tudjuk, elég pontonként az adott pont tulajdonságait eltárolni. Ezt az eltárolt paraméterek milyenségétől, a tömörítés jelenlététől és mértékétől, a pontok sorrendjétől, stream-elhetőségtől, illetve a formátum mögött álló cégektől, szervezetektől függően többféle szabvány szerint is megtehetjük. @file-formats-websource

=== PLY

A `.ply` formátumot #footnote[https://en.wikipedia.org/wiki/PLY_(file_format)] először 1994-ben adták ki, és azóta is nagyrészt változatlan a keret. Könnyen lehet vele szöveges, vagy bináris formákban csúcsokat különböző, a fejlécben definiált tulajdonságokkal eltárolni.

==== Eredeti, nézetirány-függő színekkel

<nezetiranyfuggo-ply-fejezet>

Egyszerűsége és flexibilitása miatt az eredeti @kerbl-2023-3dgs cikk a `.ply` formátumot választotta, így továbbra is ez az egyik legelterjedtebben használt formátum. A kiindulásként választott, @OriginalGGSVFejezet. fejezetben taglalt program is ezt a formátumot támogatja.

A nézetirány-függő színekhez gömbi harmonikus (spherical harmonics, SH) #footnote[https://en.wikipedia.org/wiki/Spherical_harmonics] értékeket tárolunk el minden egyes ponthoz. A csúcsonként eltárolt értékek így, az összes szokásos nézetirány-függő paraméter használata esetén a következők @file-formats-websource:
- 3 float: pozíció
- 3 float: felületi normál (nincs használva, de kötelező)
- 3 float: szín DC komponens (RGB)
- 45 float: szín gömbi harmonikus komponensek ($45 = 3 dot (3+5+7)$)
- 1 float: átlátszóság (szigmoid alkalmazása előtt)
- 3 float: skálafaktorok a 3 tengely mentén
- 4 float: elfordulás (kvaternió)

Ez a formátum így minden egyes pontonként (blob-onként) 62 lebegőpontos számot tárol el, így egy teljes jelenet könnyen meghaladja az 1GB méretet a lemezen. Ez veszteség (lossiness) és könnyű beolvashatóság szempontjából tökéletes, viszont elfoglalt tárhely szempontjából nem jó. Ezen kívül egy olyan formátumot használunk GS pontfelhők tárolására, ami nem erre lett tervezve.

==== Újravilágítható, PBR anyagtulajdonságokkal

<religtholhato-ply-format>

Mivel a formátum könnyen bővíthető, módosítható, így egyszerűen lehetséges blob-onként más adatok eltárolása. Ezt használja ki a @mesh2splat-program-fejezet. fejezetben bemutatott program is, ami ugyanabban a formátumban, de más pontonkénti adatot tárol el, más céllal.

Ezekkel az adatokkal a színeket nem az adott blob-ra történő ránézés iránya határozza meg egyedül, hanem a jelenetben szereplő fények, és egyéb faktorok is. Ennek kiterjedt irodalma van a standard grafika pipeline esetén fizikai alapú renderelés (physically based rendering, PBR) #footnote[https://en.wikipedia.org/wiki/Physically_based_rendering] néven, mivel a háromszögeket is lehet hasonló anyagtulajdonságok figyelembe vételével megvilágítani. Ennek a technikának a segítségével tudjuk a pontfelhőket is újravilágítani.

A csúcsonként eltárolt értékek a következők ezesetben:
- 3 float: pozíció
- 3 float: felületi normál, ezesetben használva is van
- 3 float: szín DC komponens, albedó (RGB)
- 1 float: PBR metallic érték
- 1 float: PBR roughness érték
- 1 float: átlátszóság (szigmoid alkalmazása előtt)
- 3 float: skálafaktorok a 3 tengely mentén
- 4 float: elfordulás (kvaternió)

Tehát a fő különbség a @nezetiranyfuggo-ply-fejezet. fejezetben taglalt formátumhoz képest az, hogy az alapértelmezett adatok (transzform, RGB+A) mellett a +45 darab SH érték helyett +2 darab PBR, illetve +3 darab normál érték nyújtja a blob színének a jelenetbeli variációjának lehetőségét.

Itt fontos megemlíteni, hogy a @mesh2splat-program-fejezet\-beli program könnyen előállítja a PBR értékeket a bemeneti mesh-ből, ezeknek az értékeknek a visszakövetkeztetése valós, inverz módszerrel felvett adathalmaz esetén viszont elképzelhetően sokkal körülményesebb, és pontatlanabb eredményt ad. Tudomásom szerint erre a problémára nincsen univerzális, könnyen használható, és széles körben pontos eredményt adó módszer. Ez nem a konkrét formátum negatívuma, hanem a teljes, @relightolhatosag-bemutatas-fejezet. fejezetben taglalt újravilágításnak a megoldandó problémája.

=== SPLAT

A tesztelések során bizonyos példamodellek a `.splat` formátumban voltak elérhetőek. Nincs formális specifikációja #footnote[https://www.polyvia3d.com/formats/splat], egy egyszerű formátum, ami által eltárolt adatok lényegileg a @nezetiranyfuggo-ply-fejezet\-beli `.ply` formátum adatainak felel meg, a SH értékeket elhagyva. A @supersplat-fejezet. fejezetben bemutatott szerkesztőprogram támogatja a formátum beolvasását, és `.ply` exportálást, az így kapott `.ply` fájl viszont némiképp eltér bizonyos más fájloktól, mivel nem garantált a paraméterek változatlan sorrendje, illetve az SH értékek nincsenek jelen.

=== GLTF/GLB

A glTF @gltf-spec egy 3D jelenetek és modellek tárolására és átvitelére használt formátum. A Khronos Group adta ki #footnote[https://en.wikipedia.org/wiki/GlTF], és az egyik legelterjedtebb nyílt formátum erre a célra. 2017-ben, a 2.0 változat megjelenésekor Juan Linietsky, a Godot Engine egyik eredeti fejlesztője a legjobb, és legígéretesebb formátumnak tartotta #footnote[https://godotengine.org/article/we-should-all-use-gltf-20-export-3d-assets-game-engines/]. 2026-ra a @gltf-szabvany forrás a legelterjedtebb 3D asset átviteli formátumnak titulálta.

A `.gltf` kiterjesztés a szöveges változatot, míg a `.glb` a bináris változatot jelenti, de tartalmilag ugyanaz van bennük. Alapesetben a bináris változat sem tartalmaz masszív tömörítést.

Habár eredetileg szintén nem GS modellekre lett a formátum kitalálva, kiterjesztésekkel viszont könnyen bővíthető: ezt használja ki a @gltf-szabvany\-ban bemutatott szabvány is, ami támogatást nyújt a glTF fájlokban történő GS modellek tárolására. Ezt a csúcspontokhoz adott extra adatok segítségével teszi meg, így az extension-t nem támogató megjelenítők is meg tudják jeleníteni a modellt, csak a pontoknak nem lesz kiterjedésük, és az egyéb, extra adatok vesznek el.

Ez alapesetben szintén nagyon nagy fájlméreteket eredményez, mivel nem tömörített formátumról beszélünk. Ezt megoldandó, a @gltf-szabvany kiterjesztés bemutatásakor már folyamatban volt a formátum bővítése, hogy tömörítést is végre lehessen hajtani. Az egyik említett módszer a @spz-fejezet. fejezetben bemutatott SPZ formátum beágyazása, amelyhez tartozó Pull Request a diplomaterv írásakor is egyeztetés, fejlesztés alatt áll #footnote[https://github.com/KhronosGroup/glTF/pull/2531].

=== SPZ
<spz-fejezet>

Az `.spz` formátumot a Niantic fejlesztette, nyílt, jól dokumentált szabvány @file-formats-websource. Agresszívan tömörít, ami a fájlméretnek előnyös, archiválási célra viszont nem. A nyers `.ply` mellett jelenleg ez a másik legelterjedtebb formátum, más-más célra jók.

=== SOG

A formátumot a @morgenstern2024compact cikk vezette be, és az ötlet mögötte az, hogy a tulajdonságokat 2D képként tároljuk el, amire aztán használhatóak a már meglevő 2D képtömörítési módszerek (pl. JPG, PNG). Szintén agresszív tömörítést tud elérni, és kevesebb veszteséget, viszont nem túl elterjedten támogatott.

== Konvertáló programok

A különböző modellek betöltéséhez és manipulációjához különböző programok használatára is szükség volt. Ezeket itt részletezem.

=== SuperSplat
<supersplat-fejezet>

A superspl.at egy könnyen használható, online szerkesztő #footnote[https://superspl.at/editor], konvertáló és publikációs felület, ami a modellek tisztításához, bizonyos blobok letörléséhez, bizonyos tárgyak környezettől történő elválasztásához kifejezetten hasznos volt számomra is. Be lehet tölteni sokféle fájlformátumot, meg lehet nézni a modellt, bizonyos részeket levágni, vagy éppen több modellt összekombinálni, majd az eredményt különböző formátumokba exportálni.

Az @supersplat_teddy. ábrán az egyik modell talapzatának levágását illusztrálom. Természetesen pontosan a Z tengely irányába nézve, a tengely ábrázolt magasságában lebegve sokkal egyszerűbb a teljes talapzatot kijelölni, és levágni.

#figure(
  image("pictures/supersplat_teddy.png")
  , caption: [A SuperSplat Editorban a Teddy modell talapzatának levágása]
) <supersplat_teddy>

=== Mesh2Splat
<mesh2splat-program-fejezet>

A Mesh2Splat az Electronic Arts GitHub felületén elérhető konvertáló program @scolari2025mesh2splat, a fejlesztő diplomatervéből nőtte ki magát. A célja, hogy a szokványos, háromszögekből álló modelleket átalakítsa GS modellekké. A felülete a @mesh2splat_suzanne. ábrán látható.

Számunkra a @relightolhatosag-bemutatas-fejezet. fejezetben taglalt újravilágításhoz hasznos, szükséges, mivel az exportálás eredményeként a pacáknak (blob-oknak) PBR anyagtulajdonságokat is ad, a @religtholhato-ply-format. fejezetben leírt formátum részeként.

#figure(
  image("pictures/mesh2splat_suzanne.png")
  , caption: [A Mesh2Splat konvertáló program betölti Suzanne-t]
) <mesh2splat_suzanne>

==== Linux port

A programot cross-platform keretrendszerben írták meg, C++-t, OpenGL-t és ImGUI-t használ, viszont nem volt sosem tesztelve Linuxon. Így ahhoz, hogy könnyen használni tudjam, bizonyos módosításokat el kellett végezzek a programon. A legfőbb módosítások pár fájlnév nagybetűjének átírása, pár Windows-only include lecserélése, és a fájl tallózásnál az útvonalban egy javítás volt.

A problémáról nyitottam egy issue-t #footnote[https://github.com/electronicarts/mesh2splat/issues/2], majd a maintainer kérésére egy pull request-et is #footnote[https://github.com/electronicarts/mesh2splat/pull/7]. Sajnos a változtatás végül nem lett merge-elve, feltételezhetően idő- vagy motivációhiány miatt, habár több embertől érkezett rá pozitív visszajelzés. Később egy másik contributor szintén elvégezte #footnote[https://github.com/electronicarts/mesh2splat/pull/22] a Linux támogatáshoz szükséges változtatásokat, amik már némiképp mások voltak, mivel a kódbázis is változott, és ez szerencsére merge-elve lett, így a projekt jelenleg már támogatja a Linuxon történő fordítást és futtatást is.

=== SplatTransform

A @gltf-szabvany által írt glTF GS extension nagyon szépen specifikálva volt, a specifikáció mellett viszont sehogyan sem sikerült találnom példafájlokat, amivel az implementációt tesztelni tudtam volna. Sajnos a @supersplat-fejezet. fejezetben bemutatott SuperSplat weblap nem támogatja, legalábbis egyelőre, a glTF exportot, így szükségem volt egy másik konverziós programra, amivel elő tudtam állítani a szükséges tesztfájlokat.

Így esett a választásom a @splattransform-gh -nél fellelhető `splat-transform` nevű parancssori programra, ami pont arra jó, hogy GS modelleket lehet vele parancssorból konvertálni.

Az installálás `npm`-en keresztül tűnt a legegyszerűbbnek, a használat pedig szerencsére nem igényelt komplex szintaktikát:

```sh
splat-transform input.ply output.gltf
```


== Használt programnyelvek ismertetése

A feladat elvégzéséhez a Godot által nyújtott környezetet szükséges használni. Erre sokféle nyelvi opció van, de a legegyértelműbb választás az alábbi.

=== A GDScript nyelv

A Godot játékmotor alapértelmezetten rendelkezik egy saját nyelvvel, ami a Python-hoz hasonlít leginkább, némi apróbb módosításokkal. Könnyű megismerni, használni, viszont compute-intenzív feladatokra nem a leggyorsabb. Szerencsére a feladat során az ismétlődő, compute-intenzív részt úgyis GPU-oldali kód fogja végezni.

Habár ez egy, a motoron belül futó scriptnyelv, a motor mégis sok funkciót elérhetővé tesz a nyelvből, így például egy vékony absztrakciós rétegen keresztül az alacsony szintű grafikus API-t is, ami általában Godot esetében Vulkan-t jelent. Ezt a RenderingDevice #footnote[https://docs.godotengine.org/en/stable/classes/class_renderingdevice.html#renderingdevice] nevű osztály segítségével teszi, és ezt tudjuk használni például a saját uniform buffer-ek, descriptor set-ek, és pipeline-ok létrehozására, menedzselésére.

A nyelv szorosan integrálva van a játékmotorba, saját, jól használható szövegszerkesztővel, és sok egyéb quality-of-life feature-rel.

=== A GDShader nyelv

Godot-ban vertex és fragment shader-t leggyakrabban `.gdshader`-ként írnak#footnote[https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html], így ezt szükséges használnunk ahhoz, hogyha GPU-oldali kóddal szeretnénk testreszabni valaminek a megjelenését. A motor rendelkezik saját editorral is a nyelvhez. A nyelv leginkább a GLSL ES-hez hasonlít, egy pár különbséggel #footnote[https://docs.godotengine.org/en/stable/tutorials/shaders/converting_glsl_to_godot_shaders.html#doc-converting-glsl-to-godot-shaders], mint például azzal, hogy egy fájlba kerül a vertex és a fragment shader.

=== A GLSL nyelv

A `.glsl` nyelv eredetileg az OpenGL-hez készült, a GPU-n történő árnyalás programozásának könnyebbé tétele érdekében #footnote[https://en.wikipedia.org/wiki/OpenGL_Shading_Language]. A később megjelent Vulkan API-val is használható, és compute shader-öket is lehet vele írni. Godot-ban a compute shader-ök írására nem hoztak létre egy külön nyelvet, így ezeket közvetlenül GLSL-ben lehet írni #footnote[https://docs.godotengine.org/en/stable/tutorials/shaders/compute_shaders.html]. A szöveg szerkesztésére saját szövegszerkesztő szükséges, a motor csak a szintaktikai ellenőrzést, és a fordítást tudja nekünk elvégezni.

== Godot bővítésének lehetőségei
<godotbovithetoseg-fejezet>

A motor hivatalosan nem támogatja a GS modellek megjelenítését, a pipeline-ja háromszöghálós modellek megjelenítésére lett kitalálva, és optimalizálva. Emiatt fontos kérdés, hogy milyen módon tudunk belenyúlni a pipeline-ba, hogy az általunk kiszámolt, gausszi pacás képet össze tudjuk kombinálni az engine által kiszámolt, háromszöghálós modellek nézetével. Ez nem egy egyértelmű feladat, és többféle módszer is rendelkezésünkre áll, előnyökkel és hátrányokkal.

=== Megjelenítés teljes képernyős quad-ként
<fsquad-fejezet>

Godot 4.3 előtt az volt a legkézenfekvőbb megoldás a problémára, hogy a teljes képernyőre rajzolunk egy téglalapot, és erre tesszük rá az általunk megjeleníteni kívánt képet. Ez egy működő megoldás, picit nehézkes megfelelően létrehozni a textúrákat, és az erőforrások felszabadítása nem egyértelmű. Ezen kívül nekünk, GDScriptből, magas szintről szükséges minden alkalommal a frissítést meghívni, ami működik, de nem a legszebb megoldás.

Ezt a megoldást implementálta a @OriginalGGSVFejezet. fejezetben bemutatott projekt, ami az én munkám kiindulópontját is adta.

=== Megjelenítés compositor effect-tel

Godot 4.3-ban megjelent egy módszer, amivel a kompozitort lehet bővíteni, CompositorEffect néven #footnote[https://docs.godotengine.org/en/stable/classes/class_compositoreffect.html]. Ezzel gyönyörűen félbe lehet szakítani a renderelés menetét, és beilleszteni a saját adatainkat a megjelenítéshez. Viszont ennek is vannak limitációi, például újravilágítás esetén nem lehet a Godot deferred shading-jét használni a splat-os modellekhez, így itt az árnyalásra más módszert szükséges alkalmazni. A @fsquad-fejezet. fejezetbeli megoldással lehetséges a Godot beépített deferred shading-jét használni.

A @kinai-repo-fejezet. fejezetben bemutatott projekt a @OriginalGGSVFejezet. fejezetbeli projektből kiindulás után áttért erre a módszerre, így a kollaboráció során az általam létrehozott kód egy része is ezt a megoldást használja.

= Tervezés

Ebben a fejezetben bemutatom a programmal, környezettel szemben támasztott elvárásokat, a megvalósítás érdekében használt architektúrát, és a projekt végrehajtásának menetét.

== Követelmények

Mint minden programmal szemben, ezzel szemben is vannak követelmények támasztva. Ezeket csoportosítani tudjuk funkcionális, és nem funkcionális követelményekre.

=== Funkcionális

Legfontosabb követelményként a megoldásnak végre kell tudnia hajtani a feladatkiírásban szereplő feladatokat, illetve ki kell tudnia elégíteni a feladatkiírásban explicit nem szereplő, de a belőle következő igényeket.

Ennek alapján a játékmotornak funkcionálnia kell a bővítés után is, látható kell legyen a (potenciálisan több) GS modell a háromszöghálós modellek mellett mélységhelyesen, ezek szükség esetén mind legyenek képesek külön mozogni, akár programozhatóan reagálni a környezetükre, részt venni a fizikában, illetve bizonyos esetben a környező fény, fények által megvilágítódni.

A program legyen képes különböző formátumú GS modelleket beolvasni, legalább a `.ply` és a `.gltf` / `.glb` fájlokat, mivel az előbbi a legelterjedtebb, az utóbbi pedig egy nagy szabványosító szervezet által jött létre, és a feladatkiírás explicit kéri.

=== Nem funkcionális

A nem funkcionális követelmények közé sorolhatók, mint általában #footnote[https://hu.wikipedia.org/wiki/Nem_funkcion%C3%A1lis_k%C3%B6vetelm%C3%A9ny], a stabilitás, erőforráshasználat, sebesség, a megjelenítés minősége és a szélesebb hardver-támogatás is. Ezek közül az erőforráshasználat szerepel explicit a feladatkiírásban, az instancing vizsgálatával, megvalósításával. A projekt során a többi tulajdonságra is figyelek, amennyiben a scope keretein belül jelentősen fejleszthetők, azt elvégzem. De az elsődleges cél a funkcionalitáson van.

== Architektúra
<architektura-fejezet>

A @godotbovithetoseg-fejezet. fejezetben bemutatott bővítési lehetőségtől függően többféle változata is lehetséges az architektúrának, és ezek közül mindkettőnek vannak előnyei és hátrányai, így mindkettővel dolgozok. Ez, és más körülmények miatt sajnos a kódbázis, és az addon különböző verziói más-más állapotban vannak. Ez azért szükséges, mivel például különböző változatait az újravilágításnak más-más verzióban, architektúrával lehet implementálni, így párhuzamosan több változat is szerepel. Ezután az egyéb feature-öket más-más kódbázisban implementálom, és a fontosabbakat portolom a másik kódbázisba is. Ez, attól eltekintve, hogy kényelmetlen, hasznos fejlődési lehetőség számomra. Ezeket az elvégzett tevékenységeket a @onallo-munka-bemutatasa. nagyfejezetben részletesen taglalom.

A kép motorba való beillesztésén kívül az architektúra megegyezik, és a következőből áll. Van egy-egy GLSL shader a rendezésre, ez a @vulkan-radix-sort-gh\-ben megjelölt könyvtár módosított változata, mivel a @OriginalGGSVFejezet. fejezetben leírt program is azt használta. Ezután a splatokat további GLSL shaderökkel vetítjük, és rendereljük. Az árnyalók menedzselését egy GDScript oldali szkript végzi, hozza létre a pipeline-t, állítja be a uniformokat, és az egyéb buffereket. Ennek segítésére létezik egy kontextus objektum, ami elabsztrahál bizonyos alacsonyabb szintű műveleteket, hogy a kód olvashatóbb legyen. Ez is GDScriptben íródott. Ez az architektúra túlnyomórészt a @OriginalGGSVFejezet. fejezetben leírt programból származik, az én feladatom ennek a bővítése, karbantartása a feladatkiírásban leírt feladatok elvégzése során.

Az egyéb bővítések, mint például a fájl importálásáért, az erőforrás (resource) definíciójáért, illetve a jelenetbe helyezhető node-leszármazottért felelős kódrészletek is mind GDScript-oldaliak. Ezeknek a felelőssége többé-kevésbé jól elhatárolt, és külön-külön fájlokban kapnak helyet. A fájlformátum beolvasása és az erőforrás definíciója és értelmezése már egy kevésbé elhatárolt terület például, ezek a felelősségi körök és célok az egyszerűség függvényében az implementáció közben könnyen meghatározhatóak, illetve módosíthatóak. A tényleges beolvasást, értelmezést végző kódrészlet az egyik objektumból a másikba könnyen átemelhető úgy, hogy a funkcionalitás ne változzon. Ez igaz az egyéb, nehezen meghatározható felelősségi körökre is.

== Projekt végrehajtása

A projekt végrehajtása során körülbelül a feladatlap sorrendjében megyek végig a funkciókon, nézek utána az implementálás lehetőségeinek, és implementálom őket. Ez a végrehajtási sorrend nem feltétlenül egyezik meg az @onallo-munka-bemutatasa. fejezetben leírt sorrenddel, mivel ott logikus sorrendben szeretném bemutatni az elvégzett munkát, néhol időben egymástól távol elvégzett, de összetartozó feladatokat együtt csoportosítva.

= Önálló munka bemutatása
<onallo-munka-bemutatasa>

Ebben a fejezetben mutatom be a fő programozási feladat megoldásának lépéseit, a feladat megoldásának érdekében elvégzett munkát. A projekt a 2024/25/2 (tavaszi) félévi Önálló laboratórium 1 című tárgy, a 2025/26/2 (tavaszi) félévi Diplomatervezés 1 című tárgy, és a 2026/27/1 (őszi) félévi Diplomatervezés 2 című tárgy témáját adta, így az alább bemutatott munka ezekből tevődik össze.

== A projekt elérhetősége

Az Önálló laboratórium 1 tárgyra készített projekt a @onlab-github-repo GitHub repository-ban érhető el, mind a programkód, a dokumentáció és prezentáció tekintetében. A Diplomaterv tárgyak során történő folytatás a @dipterv-github-repo GitHub repository-ban található, és szintén tartalmazza mind a Godot addon-t (programkódot), mind ezen dokumentumot, mind a prezentációt.

A legtöbb kód és anyag a Godot, és az egyéb felhasznált projektek szellemiségéhez híven MIT licensz alatt elérhetők. A különböző módosítások a @architektura-fejezet. fejezetben részletezett okok miatt esetlegesen különböző ágakon (branch-eken) találhatóak, ezek pontos elhelyezkedését a repository-ban található README dokumentumok leírják.

Adott a megtekintő program, amely be tud tölteni egy `.ply` kiterjesztésű splat-os modellt, és meg tudja azt jeleníteni a játékmotor keretein belül. Illetve adott példaként az autó-szimuláló program. Adottak továbbá splat-os modellek, amiket lehet használni.

== Egyszerre több pontfelhő megjelenítése
<egyszerre-tobb-pontfelho-fejezet>

A @valasztott-modszer-fejezet. fejezetben leírtaknak megfelelően a kiindulási projekt már képes egy GS modellt megjeleníteni, így az első egyértelmű feladat több pontfelhő egyidejű megjelenítése.

Erre azért van szükség, mert szeretnénk több különböző fájlból egyszerre pontfelhőket megjeleníteni: például a @vitavehicle-peldafelhasznalas-fejezet. fejezetben bemutatott példafelhasználás esetén az autó teste, és a 4 kereke rögtön 5 külön pontfelhő, más-más transzformációval.

Mivel a pontfelhők mind lényegében pontok halmaza, így ennek a megoldására azt találtam ki, hogy a CPU-n összeuniózom ezeket a pontfelhőket a GPU-ra történő feltöltés előtt, így az eddig is használt pipeline-nal lehetséges lesz több, különböző fájlból származó GS pontfelhő megjelenítése.

#figure(
  image("pictures/multiple_objects.png")
  , caption: [Egyszerre látható több pontfelhős modell]
) <multiple_objects>

Az @multiple_objects. ábrán egyszerre látszik a mozdony és a környezete, amik egy fájlból származnak, illetve a bonsai fa teteje, ami egy másik fájlból származik. A transzformáció itt még nem működik, így nem lehet mozgatni még a két modellt egymáshoz képest, ez a probléma majd az @pontfelhok_transzformacioja_fejezet. fejezetben kerül megoldásra. A pontfelhők fájljai az eredeti, @kerbl-2023-3dgs forrásban megjelölt papír példa adathalmazából származnak.

Az uniózás során elmentem azt is, hogy mely pacák indexeinél vannak a határok. Ennek segítségével a GPU-ra történő feltöltéskor egy eddig padding célt szolgáló float kihasználásával minden feltöltött splat esetén egy ID-t is továbbítok, ami megmondja, hogy az adott paca hányadik objektumhoz tartozik.

== Pontfelhők transzformációja
<pontfelhok_transzformacioja_fejezet>

A következő feladat a pontfelhők helyes transzformációja. Ez egy bonyolult feladat több szempontból: egyrészt a transzformáció rögtön 3 tevékenységet foglal magába: eltolást, forgatást és skálázást. Másrészt pedig a transzformációt több, különböző tulajdonságra is alkalmazni kell, nem triviális módon: a pozíciót, a gausszi eloszlású kiterjedés irányait, és a gömbi harmonikusok (nézetirányfüggő megcsillanások) irányait is megfelelően kell transzformálni. Ezeknek a nem megfelelő végrehajtását némely esetben könnyebb, némely esetben nehezebb észrevenni, így a @gombi-harmonikus-trafo-fejezet. fejezetben leírt javítás szükségességét jóval később fedeztem fel, mint ahogy a többi transzformációt implementáltam.

#figure(
  image("pictures/object_transformation.png")
  , caption: [A bonsai fa transzformálva van, míg a vonat helyben marad]
) <object_transformation>

A @object_transformation. ábrán ugyanúgy a vonat és környezete pontfelhő, illetve a bonsai fa láthatóak, de ezúttal a bonsai fa pacáira egy időben folyamatosan változó transzform lett applikálva: a helyesség ellenőrzése érdekében pedig ugyanezen transzform szintén alkalmazva lett két kapszula alakra, melynek kirajzolását a megfelelő helyre az engine végzi, így alkalmas a helyesség ellenőrzésére.

Egy ilyen logikájú jelenet jelenetfája a @automatic_node_discovery. ábrán látható, ez segíti a hierarchia elképzelését. A `BonsaiPath` nevű görbét tartalmazó objektum által eltárolt útvonalon képes a `PathFollow3D` nevű (és típusú) node mozogni, amely így minden képkockában új pozíciót vesz fel a görbe mentén, automatikusan propagálva a transzformot a gyerekeinek a globális transzformjába. Ezt a globális transzformot kell valamilyen módon eljuttatni a transzformációért felelős GLSL shaderbe, és (csakis) a megfelelő ID-vel rendelkező pacákra alkalmazni.

Első implementációs lépésként fix számú objektum transzformját töltöm fel: ehhez egy fix méretű új uniform buffert hozok létre, és töltöm fel új értékekkel képkockánként.

#figure(```py
const MAX_OBJECT_COUNT := 16 # number of gsplat object transforms, same as in gsplat_projection.glsl
var object_transforms : Array[Transform3D]
...
descriptors['transforms'] =
        context.create_uniform_buffer(16*MAX_OBJECT_COUNT*4)
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
```, caption: [Transzformációs mátrixok továbbítása a GPU-ra GDScript-ből]
) <objecttransform_kod>

Az @objecttransform_kod. kódrészleten látható a uniform buffer létrehozása, feltöltése, illetve a feltöltéshez használt szerializáció is, ami a GDScript oldali mátrix objektum reprezentációját átkonvertálja olyan formátummá, amit a GLSL oldalon a GPU értelmezni fog tudni. A negatív előjelek bizonyára megmagyarázhatóak, de mindenesetre szükségesek, mivel nélkülük a bonsai fa láthatóan nem ugyanott volt, mint a kapszulákból álló "repülő-alak".

Miután a GPU-n az @egyszerre-tobb-pontfelho-fejezet. fejezetben említett ID továbbítása által már lehet tudni, hogy melyik splat melyik objektumhoz tartozik, így lehetséges objektumonként más transzformációt alkalmazni a splatokra. Így az @objecttransform_kod. kódban továbbított transzformációk alkalmazása érdekében például a következő, a @objecttransform_shaderkod. kódrészleten látható GLSL kód használható:

#figure(```glsl
// same as in gaussian_splatting_rasterizer.gd
#define MAX_OBJECT_COUNT 16
...
struct Splat {
  vec3 position;
  float time;
  float covariance[6];
  float opacity;
  float id;
  float sh_coefficients[16*3];
};
...
layout (std140, set = 0, binding = 7) restrict uniform Transforms {
  mat4 transforms[MAX_OBJECT_COUNT];
};
...
// --- FRUSTUM CULLING ---
vec3 splat_pos = splat.position*model_scale;
vec4 view_pos = view_matrix * transforms[int(splat.id + 0.5)]
                * vec4(splat_pos, 1.0);
vec4 clip_pos = projection_matrix * view_pos;
...
mat3 curr_transform = mat3(transforms[int(splat.id + 0.5)]);
...
```, caption: [Transzformációs mátrixok alkalmazása a GPU-n]
) <objecttransform_shaderkod>

Itt szintén definiálva van az érkező transzformációs mátrixok uniformja, a `Splat` struktúrában minden instance esetén megtalálható az ID, hogy hányadik számú transzformációs mátrixot kell rá alkalmazni (egyszerű egész ábrázolás híján `float`-ként átadva, majd kerekítve), és látható a uniform buffer megindexelése is, a megfelelő mátrix megtalálása és alkalmazása érdekében.

=== Kiterjedés irányainak transzformációja

Külön meg kell említeni, hogy nem elegendő a fentebb bemutatott transzformációt elvégezni a gausszi eloszlású pacák pozíciójára, mivel a paca kiterjedése általában változik a tengelyek irányába, azaz a skálatényezők nem egyenlőek. Ehhez a (GPU-ra feltöltés előtt, a skálatényezőkből és az elforgatásból kiszámolt) kovariancia mátrixot, azaz a pacák kiterjedését és orientációját is transzformálni kell.

A transzformáció elvégezhető balról a transzformációs mátrixszal, jobbról pedig a transzponáltjával való szorzással. #footnote[https://github.com/chiehwangs/3d-gaussian-theory]

#figure(
  image("pictures/covariance_matrix_transformation_difference.png")
  , caption: [A kovariancia mátrix transzformációjának hiánya látható különbséget okoz]
) <covariance_matrix_transformation_difference>

Amennyiben a pacákat nem forgatjuk helyesen, akkor a @covariance_matrix_transformation_difference. ábrán bal oldalon látható eredményhez jutunk, miközben a modellt forgatjuk, vagy forgatást alkalmazunk rá. A jobb oldali teddy lenne a helyes kép, hogyha a kovariancia mátrix helyesen van transzformálva.

=== Gömbi harmonikusok transzformációjának megjavítása
<gombi-harmonikus-trafo-fejezet>

Hasonló filozófiájú, bár nehezebben észrevehető különbséget okoz, ha a gömbi harmonikusokat nem konvertáljuk megfelelően.


#figure(
  image("pictures/sh_transformation_difference.png")
  , caption: [A gömbi harmonikusok transzformációjának hiánya is észrevehető]
) <sh_transformation_difference>

A @sh_transformation_difference. ábrán bal oldalon látható a helytelen ábra, míg a jobb oldalon a helyes ábra. Hogy a fontos részletet, a fa törzsének megcsillanását jobban lehessen látni, ezt a részt kinagyítottam a felső sarkakba is. Ez a modell valószínűleg egy lego-fa, vagy legalábbis lego-hoz hasonló elemekből épülnek fel, így a sima felületen a fény bizonyos irányokból nézve meg tud csillanni. Ezt hivatottak kódolni a gömbi harmonikusok, amit viszont nem tudunk visszaadni, ha nem transzformáljuk őket helyesen.

A gömbi harmonikusok bonyolult elforgatása helyett sokkal egyszerűbb a nézeti irányt inverz-transzformálni, és értelem szerint mindkettő ugyanazt az eredményt adja, így az utóbbit implementáltam a @shtransform_shaderkod. kódrészleten látható módon.


#figure(```glsl
vec3 world_view_dir = world_pos.xyz - camera_pos;
vec3 local_view_dir = normalize(inverse(object_linear) * world_view_dir);
```, caption: [Nézeti irány helyes transzformációja GLSL-ben]
) <shtransform_shaderkod>

Ennek a problémának a felfedezését több tényező is hátráltatja: egyrészt nem minden modell rendelkezik gömbi harmonikusokkal, és még kevesebb rendelkezik ténylegesen látható különbséggel. A sokáig használt bonsai fa teszt modellem valamelyik transzformációs lépésnél elvesztette a gömbi harmonikusait, így hiába eredetileg rendelkezett volna a fentebb látható megcsillanással, azon a modellen nem is láthattam a különbséget. Ezen kívül a félig átlátszó splat-ok különböző irányokból nézve önmaguktól, gömbi harmonikusok nélkül is egészen jól tudnak nézetirány-függő színeket produkálni, így azt hiheti az ember, hogy működnek a nézetirány-függő színek, holott csak olyan a pacák elrendezése, hogy más irányból nézve más-más színt adnak vissza.

A @gltf-beolvasas-fejezet. fejezetben leírt GLTF beolvasásnál, amikor a gömbi harmonikusokat is mindenképpen ellenőrizni szerettem volna, jöttem rá, hogy tulajdonképpen ez nem működik normálisan, sőt, a példamodellemnek egyáltalán nincsenek is gömbi harmonikusai. Így újra beszereztem a modellt, ráfókuszáltam a @sh_transformation_difference. ábrán látható fatörzs megcsillanására, amit a @supersplat-fejezet. fejezetben leírt SuperSplat által adott képpel is összehasonlítottam. Ez alapján már helyesen tudtam a problémákat diagnosztizálni, és validálni a működést.

== Automata objektum-megtalálás

A helyes transzformáció alkalmazása után a következő feladat a Godot Scene Tree-jébe (jelenetfa) történő integráció. A Godot-ban alapból az egész jelenetet egy hierarchikus elrendezéssel lehet létrehozni, hasonlóan a Unity-hoz és az Unreal Engine-hez, csak flexibilisebben. Bármely node-nak lehet gyereke bármely node, és például egy `MeshInstance3D` képes a betöltött háromszöghálós modellt a saját transzformjával (pozíció, elforgatás, skála #footnote[https://docs.godotengine.org/en/stable/classes/class_node3d.html#class-node3d-property-transform]) megjeleníteni, ami természetesen magába foglalja a jelenetfában fölötte levő node-ok transzformációját is.

Ezen kívül az összes, SceneTree-be helyezhető node-típus a `Node` objektum leszármazottja, így a nagyon objektumorientált szemlélethez híven az öröklés szerint is van egy hierarchikus struktúra, ezalkalommal az osztályok között, és nem az instance-ek között. Például a `Node` leszármazottja a `Node3D`, ami többek között tartalmazza a `transform` nevű, `Transform3D` típusú field-et, és mivel az összes, 3D-ben értelmezhető objektum a `Node3D` leszármazottja, így mindnek van transzformja is.

Mi legegyszerűbben, és legintuitívabban a `MeshInstance3D` mintájára tudunk létrehozni egy `SplatCloud3D` nevű osztályt, ami közvetlen a Node3D-ből örököl (több adattagra, funkcionalitásra nincs szükségünk), és van egy adattagja, ahová be lehet tenni a betöltendő pontfelhőt. Erre viszonylag jól integrált megoldás is létezik a Godot-ban, amivel a GDScript-ben létrehozott osztály a saját script-tel megjelenik a böngészhető node-ok hierarchikus listájában is az editorban.

#figure(
  image("pictures/automatic_node_discovery.png", width: 50%)
  , caption: [Egy lehetséges SceneTree, ami SplatMesh-eket tartalmaz]
) <automatic_node_discovery>

A @automatic_node_discovery. ábrán látható egy jelenet hierarchiája, ez a @object_transformation. ábrának közel megfeleltethető: van egy, spline-on mozgó GS objektum, mellette kettő sima háromszöghálós modell ugyanazzal a transzformmal, hogy lehessen ellenőrizni a korrekt pozíciót. Ezen kívül van egy másik GS modell is, közvetlenül a gyökér gyerekeként, ő nincs transzformálva.

A GS node osztály elnevezése több revízión ment át, így néhol `SplatCloud3D`, néhol `SplatMesh`, a @kollab-onallomunka-fejezet. fejezetben említett kódbázisban `GaussianSplatNode` a neve, de mind arra a `Node3D`-leszármazottra utal, ami a SceneTree-be helyezhető, és az adott GS modellt reprezentálja, a transzformját tartalmazza, a jelenetbeli elhelyezéséért felel.

A közvetlen ebből következő feladat tehát a @automatic_node_discovery. ábrán látható két (de potenciálisan több, illetve máshová hozzáadott) objektum globális transzformját eljuttatni a rasterizerig.

Első körben egy összegyűjtő típusú kommunikációt implementáltam a `SplatMesh` és a gyökér node között, azaz a gyökér node kereste meg az összes GS node-ot, mentette el magának, majd minden új képnél begyűjtötte a globális transzformokat (azaz a node teljes transzformját, amibe a szülők transzformja is bele van számolva), és továbbította a rasterizernek. Az ehhez szükséges osztály nagyon egyszerű, a teljes kód a @pull_gsnode_gdscr. kódblokkban látható.

#figure(```py
class_name SplatMesh extends Node3D

@export var ply_file: String

func is_splat_mesh():
  pass
```, caption: [Pull esetén a GS node implementációja]
) <pull_gsnode_gdscr>

A root node feladata, a node-ok összegyűjtése picit bonyolultabb volt, és nem találtam könnyű megoldást saját típusú objektumok halmazának könnyű beszerzésére a SceneTree-ből. A legjobb megoldás egy rekurzív bejárás lett, ami az `is_splat_mesh()` függvény létezése alapján gyűjtötte össze a node-okat #footnote[https://forum.godotengine.org/t/how-do-you-get-all-nodes-of-a-certain-class/9143]. A node-okat egy tömbben eltárolta a kezdeti begyűjtés után, illetve a megfelelő fájlokkal inicializálta a rasterizert. Minden képkockában továbbá összegyűjtötte a tömbelemek aktuális transzformját, és továbbította a rasterizer @objecttransform_kod. kódrészleten látható `update_object_transforms(transforms)` függvénynek. Ez a logika viszont később át lett alakítva a @pull-vagy-push-fejezet. fejezetben leírtaknak megfelelően egy push logikájú megoldásra.

A transzformok rasterizernek való képkockánkénti továbbítása viszont aktuális maradt, és a @pull_rootnode_gdscr. kódrészleten látható módon történik.

#figure(```py
var splat_meshes : Array[SplatMesh] = []
...
func _process(delta: float) -> void:
  ...
  var splat_transforms : Array[Transform3D] = []
  for m in splat_meshes:
    splat_transforms.append(m.global_transform)
  ...
  rasterizer.update_object_transforms(splat_transforms)
```, caption: [A gyökér vagy autoload továbbítja a transzformokat a rasterizernek]
) <pull_rootnode_gdscr>

Fontos limitáció, hogy ezzel a megoldással nem támogatott új objektumok futásidejű létrehozása, eltüntetése, és láthatatlanná, illetve láthatóvá tétele sem. Ez majd szintén az @pull-vagy-push-fejezet. fejezetben kerül finomításra.

Meg szükséges említeni még a szálakat, ugyanis a rasterizer függvényeit alapvetően a render thread-en hívjuk, az objektum-transzformációk feltöltése viszont, a kameratranszformációk lekérdezéséhez hasonlóan a fő szálon történik.

== Mélységhelyes összekombinálás

#figure(
  image("pictures/depth_combination.png")
  , caption: [A mélység összekombinálásának tesztelése a vonatos jelenettel és beépített kapszulákkal]
) <depth_combination>

a @depth_combination. ábrán látható ...

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

Jobban tárgyalni ezt a problémát: Artifactos mélység: a shader kód párhuzamosan tölt be adatokat, és dolgozza fel őket, ehhez viszont szükséges shared bufferek használata

== Addon készítése

leírni hogy milyen fájlokat kellett hova tenni át, autoload, registration script, stb

== Pull vagy Push modell
<pull-vagy-push-fejezet>

RenderedImage pull vs SplatMesh push

Az eredeti megoldás szerint a RenderedImage válogatta össze a jelenetből a kirajzolandó pontfelhő node-okat, és a transzformjaikat. Ezzel az új megoldással a pontfelhő node-ok maguk regisztrálhatnak, és jelentkezhetnek le a kirajzolásról.

Ez azt is könnyűvé tette, hogy amennyiben a node láthatósága változik, akkor leregisztráljon, és ezzel eltűnjön ténylegesen a jelenetből. Ez része annak a törekvésnek, hogy a pontfelhők az editorba, illetve a játékba is jobban legyenek integrálva, azaz az editorba épített feature-ök (mint pl. a láthatóság) úgy működjenek rajtuk, mint ahogy a felhasználók várják. A nem látható pontfelhő az @lathatosag_lathato. ábrához képest a @lathatosag_nemlathato. ábrán láthatóan nem látható.

#figure(
  image("pictures/lathatosag_lathato.png")
  , caption: [Látható a plüssmaci]
) <lathatosag_lathato>


#figure(
  image("pictures/lathatosag_nemlathato.png")
  , caption: [Nem látható a plüssmaci]
) <lathatosag_nemlathato>

Hozzá kell tenni, hogy ez a megoldás még nem volt a legcélravezetőbb: minden láthatóságváltoztatáskor a teljes éppen aktuálisan látható splatos adatot feltöltöttük a GPU-ra. Ez a @igazi_dinamikus_lathatosag. fejezetben került javításra.

megemlíteni hogy egy bazinagy lagspike ellenében így már dinamikusan is hozzá lehet adni dolgokat, meg kitörölni, ami az editor-beli használaton sokat lendített, nem kell az egész jelenetet bezárni meg újra megnyitni egy változatatásért

=== Dinamikus láthatóság

a fentebbi fejezetből kiszedni az ide tartozó részt

=== Kifinomultabb dinamikus láthatóság

<igazi_dinamikus_lathatosag>

A PR készítése közben a korábbi dinamikus láthatóság problémájából kiindulva biztosan úgy akartam újból megoldani a problémát, hogy láthatóság változtatásakor ne legyen szükség az összes splat adat újbóli feltöltésére. Ez elég könnyen meg is volt oldható úgy, hogy a transzformáció mellé (ami amúgy is minden mozdulatnál újra feltöltődik) pakoltam egy igaz-hamis értéket, ami alapján a shader el tudja dobni a hozzá tartozó splatokat, ezzel megvalósítva a nemláthatóságot.

== Elsőosztályú polgárok

További editorintegrációhoz egyéb apróságokat is elvégeztem, ilyen a @editor_ikonok. ábrán látható ikonok készítése a splat-os node-okhoz, illetve resource-okhoz, a betöltés és a tárolt adat szétcsatolása, és ezzel az editor automatikusan be is tudja tölteni az eddig számára ismeretlen file-t egy Godot resource-á. Ezzel például exportált buildekhez is automatikusan hozzá tudja tenni ezt a fájlt, és ott már nem kell a betöltést lefuttatnia.

Az @tablazat_teszt. táblázatnál láthatóak a node-hoz, illetve a resource-hoz társított ikonok szöveges leírásai is. Ezzel tudom tesztelni a Typst táblázat captionjeit, illetve referenciáit.

#figure(
  image("pictures/editor_ikonok.png")
  , caption: [A Node és a Resource saját ikonokat kaptak]
) <editor_ikonok>

#figure(
  table(  columns:2,
  [GaussianSplatNode], [GaussianResource], 
  [Piros, átfedő pöttyök], [Sárga, kisebb sugarú pöttyök]
  )
  , caption: [Táblázat teszt]
) <tablazat_teszt>

=== Editor ikonok

ide áthozni / kijjebb fejteni a fentebbi szöveg tartalmát

=== Betöltés, és tárolt adat szétcsatolása

meg ide

== AMD bug kijavítása

A tesztelések során figyelmes lettem egy AMD hardveren történő bug-ra, ezt a VulkanRadixSort könyvtárra vezettem vissza, és az eltérő subgroup méret okozhatta. A hibát én is kijavítottam, és láttam azt is, hogy upstream is kijavították már, csak az általam használt eredeti megjelenítő nem frissítette a dependency-t. Ezt jeleztem az ő repositoryjukban is, a megfelelő fixet megjelölve @amd-bug-upsteam-issue. A linkelt issue-ban találhatóak a további linkek a kapcsolódó fixekre.

== CompositorEffect-es megoldás vizsgálata

<compositoreffect> Biztos ez jó referencia? nem a fentebbi, bevezető fejezetet kéne?

Godot 4.4-től már lehetőség van a rendering pipeline-ba jobban belenyúlni, CompositorEffect-eket írva. Az eddigi, eredeti megjelenítő egy QuadMesh-t jelenített meg egy MeshInstance3D-vel, ami lényegében mindig az igazi kamera előtt lebegett, így tudta a pontfelhőket megjeleníteni. Én még önlab alatt megcsináltam azt hozzá, hogy az átlátszóság alapján összeollózza az eredeti, sima raszteres kamera által adott képpel, ez viszont több helyen látszott, hogy egy elég összetákolt megoldás volt. Manuálisan kellett meghívni a saját renderelésünket, de csak akkor hogyha tényleg szükségünk volt a képre, különben elkezdett szaggatni az editor. A használt textúrák felszabadításának működése nem világos, illetve ablak átméretezésekor is le kell kezeljünk speciális dolgokat, ami nem egyértelmű, hogy teljes körűen sikerül.

== Instancing

Hogyha már itt voltam a feltöltésnél, úgy láttam, hogy a feladatkiírásban is szereplő instancinget is akkor a legmegfelelőbb implementálni. Ennél a splat-os modelleket kell különválasztani az objektumoktól.

Eddig minden splat egy extra ID-t kapott, és az ID-edik transzformációs mátrixszal lett eltranszformálva, így megoldva azt, hogy az egyes objektumok máshogyan mozogjanak. Az optimalizációs lehetőség ott jön be, hogyha 1 db kocsi helyett 10 db van a jelenetben, akkor a hozzá tartozó százezer-millió nagyságrendű splat adatait nem szükséges 10-szer tárolni a GPU-n, hiszen ezek ugyanazok.

A megoldás pedig nem nagyon nehéz: az ID buffer legyen kétszer akkora, és minden minden párban az egyik ID mondja meg a transzformációs mátrixot, a másik ID pedig a splatot. Így lehet egy modellnek több transzformációs mátrixa is, csak az ID bufferben kell kétszer benne lennie az összes splat ID-jének. Ez az `nvidia-smi` parancs használatával láthatóan jelentősen javította a memóriahasználatot: a @instancingelott. ábrán 1207MiB-t használt az instancing előtti állapot, míg az @instancingutan. ábrán 818MiB-t, a képeken látható 10-es nagyságrendű autómennyiséggel.


#figure(
  image("pictures/instancing_elott.png")
  , caption: [Instancing előtti memóriahasználat]
) <instancingelott>


#figure(
  image("pictures/instancing_utan.png")
  , caption: [Instancing utáni memóriahasználat]
) <instancingutan>

=== Instancing hatásának mérése

instancing mérése felhasznált memóriával

ez az instancing mellé menjen

=== Pull Request

== Újravilágíthatóság

A relightolhatóság egy komplex téma, de egy játékmotor esetén nagyon fontos. Alapból a gaussian splates modellek gyakran rendelkeznek gömbi harmonikusokkal kódolt nézeti irány-függő színekkel, splatonként. Ezzel lehet egyszerű tükröződéseket, csillanásokat szimulálni, és a modell tud színt változtatni annak függvényében, hogy melyik irányból nézzük.

Ezzel szemben egy relightolható / újraszínezhető modell nem nézeti irányfüggő színeket tárol magában splatonként, hanem valamilyen fajta anyagtulajdonságokat, például PBR (roughness, metallic, normal stb.) értékeket. Ennek segítségével nem csak a nézeti iránytól függhet a szín, hanem a teljes, komplex jelenettől, kiemelt hangsúlyt fektetve a fényforrás(ok)ra. Ez egy játékban kifejezetten fontos, például ha egy splat-es modell irányt változtat, akkor a nap másik oldalát süti. Ennek megfelelően a színei is teljesen megváltoznak, amit leginkább ilyen módszerekkel lehet megvalósítani.

A lehetőségek felmérésekor többféle megoldás is célravezetőnek tűnt, mindkettő a saját erősségeivel és gyengeségeivel. Végül arra jutottam, hogy mindkettőt megvalósítom, összehasonlítási céllal.

=== Saját fényszámítással

Az első lehetőség az, hogy mi adjuk át manuálisan a beszámítandó fényforrásokat, és mi számoljuk a színeket a megadott paraméterekből. A prototípust úgy csináltam, hogy egy irányfényforrást tudunk átadni. Ennek a hátránya a manuális fényforrás-összegyűjtés, illetve a shading eltérő lehet a többi, engine által shadelt mesh-étől. Hatalmas előnye viszont, hogy működik a @compositoreffect. fejezetben tagalt CompositorEffect-es megoldással.

A @relightolhato_sajatshaded. ábrán is látható, hogy a megvilágítás működik, de a @relightolhato_godotshaded. ábrához képest azért alulmarad a többi megvilágítással való egyezőségben. Ezen az ambient light állításával némiképp szerintem lehetne segíteni, de ugyanolyan jó sosem lesz.


#figure(
  image("pictures/relightolhato_sajatshaded.png")
  , caption: [Suzanne, a Blender majom megvilágítva általunk]
) <relightolhato_sajatshaded>

=== A Godot fényszámításával

elővétel: ki kellett javítani a spamelős bugot

A Godot fényszámításának használatakor viszont elő kellett venni az eredeti, Fullscreen quad-os megoldást, mivel a Godot-nak ezen kereszül tudom átadni a PBR értékeket (egy textúrában), ami alapján ő fogja elvégezni a relightolást, a belül tárolt, gyorsítótárazott, stb. fények alapján. Így ez automatikusan tudna működni pontfényforrásokra és spotlightokra is (csak még egy bug miatt nem tud, lásd @tovabbiteendok-dipterv2), amint azt a @relightolhato_spotlight. ábra is mutatja.

Még egy nagyon komoly hátránya ennek a megoldásnak, hogy ez leginkább egyáltalán nem tud félig átlátszó splat-okat kezelni (ami a gaussian splattingnél egy nagyon fontos tulajdonság), mivel a Godot-nak pixelenként csak egy színt, és PBR material tulajdonságokat lehet átadni. Az pedig nem túlzottan megoldható, hogy több félig átlátszó splat anyagtulajdonságait átlagoljuk, ezt adjuk át a Godot-nak, és továbbra is realisztikus / használható eredményt kapjunk ebből.

Megjegyzendő, hogy a Mesh2Splat-tal generált modelleknél viszont nem fontos az, hogy az átlátszóságot jól kezeljük, mivel ezek a modellek jellemzően nem sok átlátszóságot tartalmaznak, szimpla modelleknél legalábbis.

Ezen kívül viszont, alapból a @relightolhato_godotshaded. ábra jóval jobban belepasszol a jelenetbe, mint a @relightolhato_sajatshaded. ábra.

#figure(
  image("pictures/relightolhato_godotshaded.png")
  , caption: [Suzanne, a Blender majom megvilágítva Godot által]
) <relightolhato_godotshaded>


#figure(
  image("pictures/relightolhato_spotlight.png")
  , caption: [Suzanne, a Blender majom megvilágítva Godot által egy spotlight-tal is (még bugos)]
) <relightolhato_spotlight>

==== Javítás nem irányfény esetére

lepedő, asszem

meg screenshotot csinálni hozzá, magyarázatot, esetleg megemlíteni a limitációkat, bugos széleket, az is növeli az oldalszámot

== Fájlformátumok implementálása

=== SPLAT adatfájl adatainak beolvasása

Robusztusabbá tenni a `.ply` fájl-beolvasást, hogy a `.splat`-ból [SuperSplat](https://superspl.at/editor)-tal konvertált `.ply` fájlokat is képes legyen beolvasni

#figure(
  image("pictures/splat_format_buggy.png")
  , caption: [Egy `.splat` formátumú buggy modell a SuperSplat editorban]
) <splat_format_buggy>

A @splat_format_buggy. ábrán látható a példamodell, amit be szerettem volna tölteni. A konverziót `.ply` formává a @supersplat-fejezet. fejezetben bemutatott SuperSplat editor elvégzi, viszont a pontos property-k, illetve a sorrendjük nem egyezik meg a korábban megszokottal.

esetleg a teljes konkrét header-öket leírni ide? hogy hogy néz ki módosítás nélkül. Ez szerepel az eredeti, uncut screenshoton pl az önlab1 doksiban

A bemeneti adatformátum a `.ply`, illetve ennek egy speciális esete. Eredetileg a megjelenítő projekt csak olyan modelleket tudott megjeleníteni, amiknek a 62 property-je mind szerepel, és egy konkrét sorrendben van:

```
x, y, z, nx, ny, nz, f_dc_0, f_dc_1, f_dc_2, f_rest_0, f_rest_1, f_rest_2, f_rest_3, f_rest_4, f_rest_5, f_rest_6, f_rest_7, f_rest_8, f_rest_9, f_rest_10, f_rest_11, f_rest_12, f_rest_13, f_rest_14, f_rest_15, f_rest_16, f_rest_17, f_rest_18, f_rest_19, f_rest_20, f_rest_21, f_rest_22, f_rest_23, f_rest_24, f_rest_25, f_rest_26, f_rest_27, f_rest_28, f_rest_29, f_rest_30, f_rest_31, f_rest_32, f_rest_33, f_rest_34, f_rest_35, f_rest_36, f_rest_37, f_rest_38, f_rest_39, f_rest_40, f_rest_41, f_rest_42, f_rest_43, f_rest_44, opacity, scale_0, scale_1, scale_2, rot_0, rot_1, rot_2, rot_3
```

Ez akkor ütközött problémába, amikor egy másik forrásból származó modellt szerettem volna megjeleníteni, ami `.splat` formátumban volt. Addig nem probléma, hogy az online [Supersplat](https://superspl.at/editor) segítségével át lehet konvertálni ezt `.ply` fájllá, viszont ebből a modellből hiányoztak bizonyos property-k, 14 volt összesen, és a meglevők sem megfelelő sorrendben voltak:

```
x, y, z, opacity, rot_0, rot_1, rot_2, rot_3, f_dc_0, f_dc_1, f_dc_2, scale_0, scale_1, scale_2
```

Így módosítottam a beolvasó részt, hogy 0-ként olvassa a hiányzó adatokat, illetve a megfelelő pozícióba tegye a property-ket. Ez azért működik, mert ami hiányzik, az a 45 db spherical harmonikusokhoz szükséges érték, amiket lehet 0-ra inicializálni, illetve a normálvektor, amit pedig nem használ fel a beolvasó.

Példareferencia egy kódrészletre: a parse függvény az @parsefuggveny. kódrészleten látható.

#figure(```py
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
```, caption: [Példa egy kódrészlet számozására]
) <parsefuggveny>

=== GLTF adatfájl adatainak beolvasása
<gltf-beolvasas-fejezet>

sh fix a beolvasásnál, PR a kínai csávónak (link a lentebbi fejezetre)

linkelni a fájlformátumra ami fentebb van bemutatva, illetve leírni/megindokolni? hogy nem a tömörített, hanem a sima változat parszolását oldottam meg

== Kollaboráció a másik implementációval
<kollab-onallomunka-fejezet>


leírni a kezdeti kollab issue-t @kollaboracio-kezdemenyezese
leírni hogy mit hol implementáltam, fejezetszámmal hivatkozva rá vissza

megjelölni, hogy még mit vett át tőlem (amd bug fix, covarianciamátrix transzformációja a kiterjedéshez)



Ezek miatt felkerült a teendők listájára a CompositorEffect-es megoldásnak a vizsgálata is. Közben a félév során egy kínai implementáció is előkerült itt: @kinai-repo. Mérlegelve a szituációt arra jutottam, hogy nem érdemes mindkettőnknek teljesen külön dolgozni a saját programján, így átfutottam az ő kódját, és mivel mindkét projekt (és az a projekt is, amelyet mindketten használtunk: @amd-bug-upsteam-issue) MIT licensz alatt elérhető, unióztam a fontosabb feature-jeinket. A kommunikáció felvételekor leírtam 1-2 dolgot, ennek eredménye lett, hogy ő is kijavította az AMD bugot, illetve valamilyen kovarianciás matekot, amitől a splatok kiterjedései is jól lettek transzformálva, illetve ezután készítettem én is neki egy PR-t az editor ikonokkal, illetve dinamikus láthatósággal és instancinggel. Ezt ő mergeelte is, és megtagelt az acknowledgementsben is.


Én pedig az ő implementációja alapján kipróbáltam a CompositorEffect-es megoldást, és tényleg sok problémát egyből megoldott. Így az uniózott projekt már azt használja a továbbiakban.

kovarianciás fix visszareferálása, esetleg egy link a kommithoz

=== Ikonok, dinamikus láthatóság és instancing Pull Request

=== GLTF import Pull Request

=== Issue a gömbi harmonikusok helyes transzformációjáról

meg fix, megreferálni a fentebbi fejezetet

== Kitérő: Typst

A diplomaterv dokumentumának elkészítéséhez a Typst nevű nyelvet használom, ami egy modern LaTeX megfelelő. Dani nevű szobatársam segítségével konvertáltuk a sablonokat (főleg ő), ez elérhető itt: @typst-bme-dipterv-sablon.

=== Rövid bemutatás

open source, cég háttere, szintaktika, elterjedés

=== Miért jobb

word/libreoffice-nál, latexnél

Word:
kód blokkok, számozás, képek számozása (?), bibliography beszúró GUI izébizénél sokkal egyszerűbb, stb

LaTeX:
20 package a fordításhoz, hosszú build time, csúnya szintaktika, végtelen mennyiségű fájl amik elég nehezen átláthatók, fordításkor is teleszemeteli a dolgot

összességében az élmény milyen

= Plugin alkalmazásai, eredmények


== Használati utasítás

Hogyan lehet betenni egy már meglevő projektbe, mi az h godot addon, stb stb

== Autó szimulátor, mint példafelhasználás
<vitavehicle-peldafelhasznalas-fejezet>

leírni hogy mi ez a projekt, esetleg külön alfejezetben bemutatni @vitavehicle-gh

@vitavehicle_car. ábrán az eredeti program látható

#figure(
  image("pictures/vitavehicle_car.png")
  , caption: [Példa képernyőkép a VitaVehicle autószimulátorról]
) <vitavehicle_car>


A splat-os és az autós Godot projektek összefésülése egészen könnyen ment, a fájlok összemásolásán túl a `project.godot` fájlt kellett kompatibilissá tenni mindkét projekt részére, többek között a definiált (billentyűzet) bemenetet, és a globális scripteknek megfelelő scripteket (autoload) kellett átemelni. Szerencsére a `project.godot` egy szöveges fájlformátum, sima config fájlként viselkedik, így akár kézzel is könnyű volt az egyes bejegyzéseket átemelni, a maradék beállítást pedig könnyen megtaláltam az editorban.

Továbbá mindkét projektben volt az alapértelmezett jelenet, aminek a node-jaihoz a szükséges scriptek hozzá voltak adva. Kis logikázás után úgy láttam, hogy a splat-os projekt gyökérnode-ja kell, hogy maradjon, többek között azért is, hogy a hozzáadott SplatMesh-eket megtalálja a jelenetben. Nem volt különösebb gond az autós projekttel, ha annak a gyökérnode-ját a splat-os projekt gyökérnode-ja gyerekeként tettem be.


#figure(
  image("pictures/vitavehicle_project_combination.png")
  , caption: [A VitaVehicle projekt összekombinálása a GS megjelenítővel]
) <vitavehicle_project_combination>

A @vitavehicle_project_combination. ábrán együtt látható a pontfelhős és a háromszöghálós autó, tesztelve a korrekt pozíciót és reakciót a környezetre

#figure(
  image("pictures/vitavehicle_end_result.png")
  , caption: [A kombinálás végső eredménye]
) <vitavehicle_end_result>

@vitavehicle_end_result. ábrán látható a kombinálás végső eredménye: két, külön irányítható GS modell alapú autó (külön forgó, kormányozható kerekekkel), illetve egy plüssmaci, ami fizikailag reagál az autókra: eltolható, ha nekimegyünk.


=== Stuttering bug

Ami következményként nehézséget okozott, az a stuttering kiküszöbölése, amit az okozott, hogy az autós projektben a kamerát egy script állította, míg a splatos projektben ugyanezen (aktív) kamera transzformációját egy script továbbította a GPU-nak, és ez a két script valamiért nem meghatározott sorrendben futott. A process priority állításával a probléma megoldódott.

képek inkább ez után a fejezet után? lehet h jobban fel lehetne osztani ezt a részt

== When Hamsters Attack TD, mint példafelhasználás

leírni hogy mi ez a projekt, esetleg külön alfejezetben bemutatni

játék bemutatása, integrációja a pluginnal, mint példa felhasználás
@when-hamsters-attack-td

erről részletesen beszélni (pl object pooling, animáció alkalmazása, ilyenek)

képek teamsről pl? vagy új screenshotok csinálása? (vszeg ennek a gépnek a screenshots mappájában is megvan)

megemlíteni a licenszt, hogy az eredeti projekt miatt gpl lett (és ténylegesen átírni a repo-ban a licenszt!)

== Asset library plugin

Felkerül végre?? igen

leírni hogy milyen kontribúcióim vannak benne

== Még mit lehetne értékelésnek, eredménynek?

objektív szempontok szerint összehasonlítani a többféle implementációt (2 féle relightolás, kínai vs saját branch, stb.)

igen pl a relightolást jól össze lehet hasonlítani, mert az 3 teljesen különböző megoldás

= Összefoglaló

Sokat tanultunk a dipterv alatt, megismerkedtünk ezzel, azzal, godot rendering pipeline, gaussian splatting, fájlformátumok, typst, stb

a plugin használható, viszonylag jó integrációval, fenn van (??) az asset store-ban, hozzátettem bizonyos fejlesztéseket, mások meg itt és itt érhetők el, ... (külön asset store item a relightolható mesh-esnek??, ha nem merge-eli majd?)


#bibliography("bibliography.yml")

#show: appendix



= További teendők a Dipterv 2-ig (végleges doksi leadásig)
<tovabbiteendok-dipterv2>

- a WhenHamstersAttackTD @when-hamsters-attack-td játék átírása félig (vagy teljesen) GSplatos modellek használatára
- ezen dokumentum finomítása, véglegesítése
  - irodalomjegyzék vs lábjegyzet? Melyiket mennyire? Mind mehet irodalomjegyzékbe, nem baj ha nagyon sok?
- TODO-k kijavítása, eltüntetése itt is és a kódban is
- minden kép, táblázat és kódrészlet be van számozva? és rendesen referálva?
- commit history-t, ai chat history-t, teams chatet visszaolvasni, hogy ne hagyjak ki semmit, amiről lehet írni

*!!!kérdések:*
- kódolás rész kész, más nem kell
- fejezetek sorrendje!
- irodalomjegyzék vs lábjegyzet
- kedvezményes tanrend nem kell
- terv szerint heti kb 5 oldal finomítása, mostmár inkább 10 xd (október eleje)

== Egyéb TODO-k


 TODO margó tükrözés rendesen, ha 2 oldalasat szeretnék, és a feladatkiíráshoz is a megfelelő margó! Illetve a legvégén: jól legyenek párosítva az oldalak, ha tényleg 2 oldalasat csinálok (tartalomjegyzék-tartalomjegyzék, absztrakt-abstract, stb.)


TODO Valahova a féléves beosztásokat: mi volt önlab1, mi dipterv1, mi dipterv2

TODO Daninak a sablonban levő módosításokat elküldeni, ha már kb fix

TODO jól elkülöníthető amit ténylegesen én csináltam, meg amit átvettem/amiről csak írok? ne időrendi sorrendben menjek a cuccokon végig, hanem logikai sorrendben.
 
TODO minden bibliography item fel lett használva valahol? footnote vs bibliography jól van kb elválasztva? (nincs többször ugyanaz a footnote, de a bibliography-k tényleg fontos h bibliography-k legyenek?)

TODO GH readme-be, illetve doksiba is (?) beírni, hogy melyik branch-en mi van. cleanup a githubon is, hogy értelmesen, jól nézzen ki. Fontos, leírtam h a readmeben olvasható h melyik branchen mi van! Plusz prezentációt is feltölteni majd!!!

whenhamstersattacktd gpl vs mit??? valahogy feloldani a readmevel, vszeg gpl-é tenni a portot

Az egészet beadni AI-nak pl nyelvtani javításra (egy random helyen eglépelni, hogy észreveszi-e!!!)

kódrészletek ne legyenek nagyon durván félbevágva (főleg a kis kódrészletek), meg képek miatt ne legyenek óriási szóközök. Ezt miután már nem lesz tartalmi változás

időben elküldeni az egészet reviewra (pl november eleje-közepe)

megkérdezni Mártont h jó-e 2 oldalasra, ha mindenképp úgy szeretném

tervezett ütemterv:
- végigmenni az egész szövegen ami van, megfelelő sorrendbe tenni a dolgokat, kb legyen meg a szöveg, struktúra
- AI táblázat betétele
- újra végigfutni mindenen, absztraktok, dolgozat szerkezete, egyéb TODO-k letisztázása
- képaláírások, kódaláírások rendben vannak? sehol sincs copy-paste ami nem oda tartozik?
- AI nyelvtani korrekció tesztje (viabilis megoldás-e, minél több hiba, magyartalan szöveg javítása)
- fentebbi todo-k átfutása, hogy van-e valami releváns
- elküldeni a konzulensnek, még mivel érdemes kiegészíteni, átrendezés, ilyesmi stb.
- legyen meg a szövegmennyiség kg-ra
- újabb nyelvtani ellenőrzés
- a/az az ábráknál / fejezetcímeknél kifejezetten! ezt már miután semmi átrendezés / új beszúrás nincs
- valamit tartalmilag totál elírni, hogy azt megtalálja-e egy AI, hha valahol totál marhaság lenne

beadás után nyomtatás, + a diasor elkészítése míg amíg jól emlékszem a dokumentumra!


ötletek a méret növelésére:
- nerf megemlítése / kijjebb fejtése
- irodalomkutatáshoz screenshotok, kipróbálni a dolgokat amiket referálok, illetve még írni róluk

*TODO AI táblázat majd ide!*


// vim:spelllang=hu:spell
