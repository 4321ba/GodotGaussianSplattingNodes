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

A Gaussian Splatting egy inverz rendering módszer, aminél a jelenetet Gauss-i eloszlású átlátszósággal rendelkező 3D foltokkal próbáljuk a lehető legjobban leírni. @kerbl-2023-3dgs Képekből előállítani a 3D modellt elég erőforrásigényes, viszont a modellek megjelenítése megfelelő minőség esetén kifejezetten közeli tud lenni a valósághoz. Nagy előnye, hogy a megjelenítőt sima, standard grafikus csővezetékkel is lehetséges implementálni, és valós időben, 100-as nagyságrendű FPS-sel renderelhető. 

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

2Retr0 GS megjelenítője @OriginalGodotGaussianSplattingViewer az eredetileg leginkább használt implementáció. Ez egy darab GS modellt képes Godot-ban megjeleníteni, és egy repülő kamerával lehet körüljárni a modellt.

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

A motor hivatalosan nem támogatja a GS modellek megjelenítését, a pipeline-ja háromszöghálós modellek megjelenítésére lett kitalálva, és optimalizálva. Emiatt fontos kérdés, hogy milyen módon tudunk belenyúlni a pipeline-ba, hogy az általunk kiszámolt, gausszi pacás képet össze tudjuk kombinálni az engine által kiszámolt, háromszöghálós modellek nézetével. Ez nem egy egyértelmű feladat, és többféle módszer is rendelkezésünkre áll, előnyökkel és hátrányokkal.

=== Megjelenítés teljes képernyős quad-ként
<fsquad-fejezet>

Godot 4.3 előtt az volt a legkézenfekvőbb megoldás a problémára, hogy a teljes képernyőre rajzolunk egy téglalapot, és erre tesszük rá az általunk megjeleníteni kívánt képet. Ez egy működő megoldás, picit nehézkes megfelelően létrehozni a textúrákat, és az erőforrások felszabadítása nem egyértelmű. Ezen kívül nekünk, GDScriptből, magas szintről szükséges minden alkalommal a frissítést meghívni, ami működik, de nem a legszebb megoldás.

Ezt a megoldást implementálta a @OriginalGGSVFejezet. fejezetben bemutatott projekt, ami az én munkám kiindulópontját is adta.

=== Megjelenítés compositor effect-tel

Godot 4.3-ban megjelent egy módszer, amivel a kompozitort lehet bővíteni, CompositorEffect néven #footnote[https://docs.godotengine.org/en/stable/classes/class_compositoreffect.html]. Ezzel gyönyörűen félbe lehet szakítani a renderelés menetét, és beilleszteni a saját adatainkat a megjelenítéshez. Viszont ennek is vannak limitációi, például újravilágítás esetén nem lehet a Godot deferred shading-jét használni a splat-os modellekhez, így itt az árnyalásra más módszert szükséges alkalmazni. A @fsquad-fejezet. fejezetbeli megoldással lehetséges a Godot beépített deferred shading-jét használni.

A @kinai-repo-fejezet. fejezetben bemutatott projekt a @OriginalGGSVFejezet. fejezetbeli projektből kiindulás után áttért erre a módszerre, így a kollaboráció során az általam létrehozott kód egy része is ezt a megoldást használja.

= Tervezés

TODO

Hogy érdemes taglalni? Lehet időrendben (problémák felmerülésének, logikus megoldásának sorrendjében)? Vagy témánként (pl ha időben két külön helyen jött elő a dinamikus láthatóságváltoztatás, akkor azt vonjam össze)? Vagy fájlonként?

Nem időrendben, az biztos. Talán a legjobb lenne kilapítani az időrendi nagyfejezeteket, és csak témánként csoportosítani. 1:1 fájlonként nem lehet jól végigmenni, mert annyiféle branch van, meg a témák általában fájlokon keresztül mennek. Tehát témák mint alfejezetek.

== Követelmények

ez nem biztos, hogy ide a legjobb, de valahova mehetne

=== Funkcionális

=== Nem funkcionális

== Architektúra

Milyen osztályok vannak, mik singleton/autoload-ok, milyen shaderek hívódnak meg, és ezeknek mik a felelősségi körei

== Relightolás logikája (hova?)


= Önálló munka bemutatása

<onallo-munka-bemutatasa>

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


== Dipterv 1 alatt végzett megoldás felvázolása

=== RenderedImage pull vs SplatMesh push

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

=== Elsőosztályú polgárok

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

=== AMD Bug

A tesztelések során figyelmes lettem egy AMD hardveren történő bug-ra, ezt a VulkanRadixSort könyvtárra vezettem vissza, és az eltérő subgroup méret okozhatta. A hibát én is kijavítottam, és láttam azt is, hogy upstream is kijavították már, csak az általam használt eredeti megjelenítő nem frissítette a dependency-t. Ezt jeleztem az ő repositoryjukban is, a megfelelő fixet megjelölve @amd-bug-upsteam-issue. A linkelt issue-ban találhatóak a további linkek a kapcsolódó fixekre.

=== CompositorEffect
<compositoreffect>

Godot 4.4-től már lehetőség van a rendering pipeline-ba jobban belenyúlni, CompositorEffect-eket írva. Az eddigi, eredeti megjelenítő egy QuadMesh-t jelenített meg egy MeshInstance3D-vel, ami lényegében mindig az igazi kamera előtt lebegett, így tudta a pontfelhőket megjeleníteni. Én még önlab alatt megcsináltam azt hozzá, hogy az átlátszóság alapján összeollózza az eredeti, sima raszteres kamera által adott képpel, ez viszont több helyen látszott, hogy egy elég összetákolt megoldás volt. Manuálisan kellett meghívni a saját renderelésünket, de csak akkor hogyha tényleg szükségünk volt a képre, különben elkezdett szaggatni az editor. A használt textúrák felszabadításának működése nem világos, illetve ablak átméretezésekor is le kell kezeljünk speciális dolgokat, ami nem egyértelmű, hogy teljes körűen sikerül.

=== Addon-ok uniózása

Ezek miatt felkerült a teendők listájára a CompositorEffect-es megoldásnak a vizsgálata is. Közben a félév során egy kínai implementáció is előkerült itt: @kinai-repo. Mérlegelve a szituációt arra jutottam, hogy nem érdemes mindkettőnknek teljesen külön dolgozni a saját programján, így átfutottam az ő kódját, és mivel mindkét projekt (és az a projekt is, amelyet mindketten használtunk: @amd-bug-upsteam-issue) MIT licensz alatt elérhető, unióztam a fontosabb feature-jeinket. A kommunikáció felvételekor leírtam 1-2 dolgot, ennek eredménye lett, hogy ő is kijavította az AMD bugot, illetve valamilyen kovarianciás matekot, amitől a splatok kiterjedései is jól lettek transzformálva, illetve ezután készítettem én is neki egy PR-t az editor ikonokkal, illetve dinamikus láthatósággal és instancinggel. Ezt ő mergeelte is, és megtagelt az acknowledgementsben is.


Én pedig az ő implementációja alapján kipróbáltam a CompositorEffect-es megoldást, és tényleg sok problémát egyből megoldott. Így az uniózott projekt már azt használja a továbbiakban.

=== Igazi dinamikus láthatóság
<igazi_dinamikus_lathatosag>

A PR készítése közben a korábbi dinamikus láthatóság problémájából kiindulva biztosan úgy akartam újból megoldani a problémát, hogy láthatóság változtatásakor ne legyen szükség az összes splat adat újbóli feltöltésére. Ez elég könnyen meg is volt oldható úgy, hogy a transzformáció mellé (ami amúgy is minden mozdulatnál újra feltöltődik) pakoltam egy igaz-hamis értéket, ami alapján a shader el tudja dobni a hozzá tartozó splatokat, ezzel megvalósítva a nemláthatóságot.

=== Instancing

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


=== Relightolhatóság

A relightolhatóság egy komplex téma, de egy játékmotor esetén nagyon fontos. Alapból a gaussian splates modellek gyakran rendelkeznek gömbi harmonikusokkal kódolt nézeti irány-függő színekkel, splatonként. Ezzel lehet egyszerű tükröződéseket, csillanásokat szimulálni, és a modell tud színt változtatni annak függvényében, hogy melyik irányból nézzük.

Ezzel szemben egy relightolható / újraszínezhető modell nem nézeti irányfüggő színeket tárol magában splatonként, hanem valamilyen fajta anyagtulajdonságokat, például PBR (roughness, metallic, normal stb.) értékeket. Ennek segítségével nem csak a nézeti iránytól függhet a szín, hanem a teljes, komplex jelenettől, kiemelt hangsúlyt fektetve a fényforrás(ok)ra. Ez egy játékban kifejezetten fontos, például ha egy splat-es modell irányt változtat, akkor a nap másik oldalát süti. Ennek megfelelően a színei is teljesen megváltoznak, amit leginkább ilyen módszerekkel lehet megvalósítani.

A lehetőségek felmérésekor többféle megoldás is célravezetőnek tűnt, mindkettő a saját erősségeivel és gyengeségeivel. Végül arra jutottam, hogy mindkettőt megvalósítom, összehasonlítási céllal.

==== Saját fényszámítással

Az első lehetőség az, hogy mi adjuk át manuálisan a beszámítandó fényforrásokat, és mi számoljuk a színeket a megadott paraméterekből. A prototípust úgy csináltam, hogy egy irányfényforrást tudunk átadni. Ennek a hátránya a manuális fényforrás-összegyűjtés, illetve a shading eltérő lehet a többi, engine által shadelt mesh-étől. Hatalmas előnye viszont, hogy működik a @compositoreffect. fejezetben tagalt CompositorEffect-es megoldással.

A @relightolhato_sajatshaded. ábrán is látható, hogy a megvilágítás működik, de a @relightolhato_godotshaded. ábrához képest azért alulmarad a többi megvilágítással való egyezőségben. Ezen az ambient light állításával némiképp szerintem lehetne segíteni, de ugyanolyan jó sosem lesz.


#figure(
  image("pictures/relightolhato_sajatshaded.png")
  , caption: [Suzanne, a Blender majom megvilágítva általunk]
) <relightolhato_sajatshaded>

==== A Godot fényszámításával

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

== Dipterv 2 alatt végzett munka 

=== Relightolható bugfix

=== GLTF import

sh fix, PR a kínai csávónak

linkelni a fájlformátumra ami fentebb van bemutatva, illetve leírni/megindokolni? hogy nem a tömörített, hanem a sima változat parszolását oldottam meg

=== Gömbi harmonikusok transzformációjának megjavítása

Issue fix-szel a kínai csávónak

=== Játékfejlesztés nagyházi mint példafelhasználás (vagy ez legyen az értékelés fejezetben??)

TODO még meg kell csinálni


== Instancing mérése felhasznált memóriával

ez az instancing mellé menjen

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

= Plugin alkalmazásai, eredmények (volt: Önálló munka értékelése, eredmények)


== Autó szimulátor önlab1ből

== When Hamsters Attack TD

játék bemutatása, integrációja a pluginnal, mint példa felhasználás
@when-hamsters-attack-td

erről részletesen beszélni (pl object pooling, animáció alkalmazása, ilyenek)

== Asset library plugin

Felkerül végre??

== Még mit lehetne értékelésnek, eredménynek?

objektív szempontok szerint összehasonlítani a többféle implementációt (2 féle relightolás, kínai vs saját branch, stb.)

igen pl a relightolást jól össze lehet hasonlítani, mert az 3 teljesen különböző megoldás

értékelés lehet fentebb, összefonva a renderer bemutatással pl, és akár külön (nagy)fejezet a WHATD

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

TODO GH readme-be, illetve doksiba is (?) beírni, hogy melyik branch-en mi van. cleanup a githubon is, hogy értelmesen, jól nézzen ki.

Az egészet beadni AI-nak pl nyelvtani javításra

időben elküldeni az egészet reviewra (pl november eleje-közepe)

tervezett ütemterv:
- végigmenni az egész szövegen ami van, megfelelő sorrendbe tenni a dolgokat, kb legyen meg a szöveg, struktúra
- AI táblázat betétele
- újra végigfutni mindenen, absztraktok, dolgozat szerkezete, egyéb TODO-k letisztázása
- AI nyelvtani korrekció tesztje (viabilis megoldás-e, minél több hiba, magyartalan szöveg javítása)
- fentebbi todo-k átfutása, hogy van-e valami releváns
- elküldeni a konzulensnek, még mivel érdemes kiegészíteni, átrendezés, ilyesmi stb.
- legyen meg a szövegmennyiség kg-ra
- újabb nyelvtani ellenőrzés
- valamit tartalmilag totál elírni, hogy azt megtalálja-e egy AI, hha valahol totál marhaság lenne

beadás után nyomtatás, + a diasor elkészítése míg amíg jól emlékszem a dokumentumra!


ötletek a méret növelésére:
- nerf megemlítése / kijjebb fejtése
- irodalomkutatáshoz screenshotok, kipróbálni a dolgokat amiket referálok, illetve még írni róluk

*TODO AI táblázat majd ide!*


// vim:spelllang=hu:spell
