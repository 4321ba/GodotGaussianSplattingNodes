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
  
  Napjainkban igen komoly fejlődésen mentek keresztül az inverz grafikai módszerek, amelyek a képalkotás folyamatát megfordítva végeznek 3D rekonstrukciót képi információk alapján. Ezek között kiemelten nagy figyelmet kapott a 3D Gaussian Splatting (3DGS), amely a színteret egy speciális, gaussi normális eloszlásokkal kiegészített pontfelhőként reprezentált radiancia mező formájában rekonstruálja. Ezen reprezentáció renderelése igen hatékonyan elvégezhető, a klasszikus 3D modellek raszterezéséhez hasonló módon. A 3DGS reprezentáció igen széles körben kezd elterjedni, már ipari szabványok is kezdenek megjelenni.
  
  Ezen korszerű technológia egy különösen érdekes alkalmazása grafikus assetek előállítása számítógépes játékokhoz, pl. a népszerű Godot engine-ben. A Godot játékmotor egy könnyű, szabad és nyílt forráskódú megoldás játékok és szimulációk készítésére.

  A diplomaterv során integrálom a 3DGS megjelenítést a játékmotorba, lehetővé téve a hagyományos 3D modellekkel való együttes megjelenítést, és fizikai interakciót. Készítek egy plugint, és így egy másik Godot projektbe is könnyen lehet integrálni a Gaussian Splatting modelleket. Külön figyelmet fordítok apró részletekre, amik a játékmotorbeli használat élményét javítják. Továbbá implementálok instancing-et a 3DGS modellekhez, illetve több újravilágíthatóság-módszert megvizsgálok. Egy közben megjelent konkurens implementációval kapcsolatba lépek, és kollaborációt hajtunk végre.

  Végül a projekt eredményének bemutatásaként integrálom a plugint több példaprojektbe, vegyesen használva 3DGS és klasszikus 3D modelleket, majd összehasonlítom a különböző logikájú újravilágítás-implementációkat.

  
  = Abstract

  In recent years, inverse graphics methods, which reverse the image-generation process to perform 3D reconstruction from visual data, have undergone significant development. Among these, 3D Gaussian Splatting (3DGS) has gained special attention. It reconstructs a scene as a radiance field represented by a specialized point cloud enhanced with Gaussian distributions. This representation can be rendered very efficiently, in a way similar to the rasterization of traditional 3D models. 3DGS is becoming widely adopted, as industry standards are already beginning to emerge.

  A particularly interesting application of this modern technology is creating graphical assets for video games, such as in the popular Godot engine. Godot is a lightweight, free and open-source game engine for developing games and simulations.

  In this master's thesis, I integrate 3DGS rendering into the game engine, enabling combined rendering and physical interaction alongside traditional 3D models. I develop a plugin that allows Gaussian Splatting models to be easily integrated into other Godot projects. I pay special attention to small details that improve the user experience within the engine. Additionally, I implement instancing for 3DGS models, investigate multiple relighting methods, and collaborate with a competing implementation that emerged during the course of the project.

  Finally, to demonstrate the results, I integrate the plugin into multiple sample projects while using a mix of 3DGS and traditional 3D models, and compare relighting implementations with different underlying approaches.
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

A továbbiakban bemutatom a témában zajló kutatás-fejlesztés legfőbb eredményeit, és ismertetem a használandó fájlformátumokat, konvertáló programokat és egyéb technológiákat. Ezután bemutatom a projekt tervezését, majd a megvalósítását témák szerint csoportosított módon. Végül a projekt használatára adok példákat, részletes összehasonlítást végzek az újravilágíthatóság-implementálások között, és összefoglalom a leírtakat.

= Irodalomkutatás

== Gaussian Splatting témájú cikkek

=== 3D Gaussian Splatting for Real-Time Radiance Field Rendering

A Gaussian Splatting (GS) technológiát az @kerbl-2023-3dgs cikk vezette be, ami ezután felkapott téma lett. A szerzők többek között különböző Neural radiance field (NeRF) #footnote[https://en.wikipedia.org/wiki/Neural_radiance_field] implementációkhoz hasonlították a saját implementációjukat, túlszárnyalva azokat pontosságban, és valósidejű megjelenítésben. Az általuk készített megoldás nem csak megjelenítést tartalmaz, hanem a képekből történő paraméteroptimalizációt is, ami a GS modelleket, pontfelhők paramétereit állítja elő.

=== Újravilágíthatóság

<relightolhatosag-bemutatas-fejezet>

Az eredeti @kerbl-2023-3dgs cikk nézetiránytól függő színeket lehetővé tett a kiterjedt pontoknak, viszont ezek beégetett színek, azaz egy adott modell egy adott irányból mindig ugyanúgy fog kinézni, fényektől függetlenül. Ez egy teljes 3D jelenet rekonstrukciójánál egy teljesen jó eredményt adó megoldás, viszont egy-egy különálló, dinamikus transzformációval rendelkező modell esetén nem mindig ad az elvártnak megfelelő eredményt. Ez különösen fontos lehet egy játékmotor esetén, ahol általában fények is vannak egy jelenetben, és a GS modell nem odaillőnek tűnhet, ha nem reagál a fényekre az elvárt módon.

Ennek megoldására többféle lehetőség van, más-más előnyökkel és hátrányokkal. A @scolari2025mesh2splat forrásban megjelölt program segít bizonyos fajta, újravilágítható pontfelhőket generálni háromszöghálós modellekből, ennek a fájlformátumnak a részletezése a @religtholhato-ply-format fejezetben található. Ezen kívül a @kinai-repo implementációban is található újravilágítás opció, ami jelentősen különbözik a fentebbi fájlformátum alkalmazásától.

=== Időbeliség
<idobeliseg-fejezet>

Külön izgalmas feladat, ha időben is változik a felvett jelenet, ilyenkor a pontfelhő időbeli transzformációját is el lehet tárolni, és ugyanazt a mozgó jelenetet akár több szemszögből, vagy mozgó szemszögből visszajátszani. Különböző pontfelhők utólagos szerkesztésére is lehetőség van. Erről szól az @4dgs-wu-time cikk.

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

Eközben, amint felbukkant a @kinai-repo-fejezet. fejezetben leírt projekt, kollaborációt kezdeményeztem @kollaboracio-kezdemenyezese, amelyet a másik fél elfogadott. Ezt megkönnyítette, hogy mindketten a @OriginalGGSVFejezet\-beli kódbázisból indultunk ki, így sok része a kódnak megegyezett. Némely fejlesztéseket én végeztem el, némelyeket ő, melyeket többé-kevésbé átvettünk egymástól. Ezt könnyen lehetővé tette az, hogy mindhárom kódbázis MIT licensszel rendelkezik, így lényegében a licensz és a copyright bemásolásával bármelyik kódot bárki felhasználhatja, még akár zárt forráskódú projektben is #footnote[https://en.wikipedia.org/wiki/MIT_License]. Így például a feladatkiírásban szereplő feladatok megoldásával is, több Pull Request-et készítettem neki. A kollaborációt a @kollab-onallomunka-fejezet. fejezetben részletezem.

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

Ezekkel az adatokkal a színeket nem az adott blob-ra történő ránézés iránya határozza meg egyedül, hanem a jelenetben szereplő fények, és egyéb faktorok is. Ennek kiterjedt irodalma van a standard grafika pipeline esetén fizikai alapú renderelés (physically based rendering, PBR @pbr-wiki) néven, mivel a háromszögeket is lehet hasonló anyagtulajdonságok figyelembe vételével megvilágítani. Ennek a technikának a segítségével tudjuk a pontfelhőket is újravilágítani.

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
<splat-formatum-fejezet>

A tesztelések során bizonyos példamodellek a `.splat` formátumban voltak elérhetőek. Nincs formális specifikációja #footnote[https://www.polyvia3d.com/formats/splat], egy egyszerű formátum, ami által eltárolt adatok lényegileg a @nezetiranyfuggo-ply-fejezet\-beli `.ply` formátum adatainak felel meg, a SH értékeket elhagyva. A @supersplat-fejezet. fejezetben bemutatott szerkesztőprogram támogatja a formátum beolvasását, és `.ply` exportálást, az így kapott `.ply` fájl viszont némiképp eltér bizonyos más fájloktól, mivel nem garantált a paraméterek változatlan sorrendje, illetve az SH értékek nincsenek jelen.

=== GLTF/GLB
<gltf-bemutatas-fejezet>

A glTF @gltf-spec egy 3D jelenetek és modellek tárolására és átvitelére használt formátum. A Khronos Group adta ki #footnote[https://en.wikipedia.org/wiki/GlTF], és az egyik legelterjedtebb nyílt formátum erre a célra. 2017-ben, a 2.0 változat megjelenésekor Juan Linietsky, a Godot Engine egyik eredeti fejlesztője a legjobb, és legígéretesebb formátumnak tartotta #footnote[https://godotengine.org/article/we-should-all-use-gltf-20-export-3d-assets-game-engines/]. 2026-ra a @gltf-szabvany forrás a legelterjedtebb 3D asset átviteli formátumnak titulálta.

A `.gltf` kiterjesztés a szöveges változatot, míg a `.glb` a bináris változatot jelenti, de tartalmilag ugyanaz van bennük. Alapesetben a bináris változat sem tartalmaz masszív tömörítést.

Habár eredetileg szintén nem GS modellekre lett a formátum kitalálva, kiterjesztésekkel viszont könnyen bővíthető: ezt használja ki a @gltf-szabvany\-ban bemutatott szabvány is, ami támogatást nyújt a glTF fájlokban történő GS modellek tárolására. Ezt a csúcspontokhoz adott extra adatok segítségével teszi meg, így az extension-t nem támogató megjelenítők is meg tudják jeleníteni a modellt, csak a pontoknak nem lesz kiterjedésük, és az egyéb, extra adatok vesznek el. A kiterjesztés részletes leírása a @GLTFExtSpec forrás alatt érhető el.

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
<splattransform-fejezet>

A @gltf-szabvany által írt glTF GS extension nagyon szépen specifikálva volt, a specifikáció mellett viszont sehogyan sem sikerült találnom példafájlokat, amivel az implementációt tesztelni tudtam volna. Sajnos a @supersplat-fejezet. fejezetben bemutatott SuperSplat weblap nem támogatja, legalábbis egyelőre, a glTF exportot, így szükségem volt egy másik konverziós programra, amivel elő tudtam állítani a szükséges tesztfájlokat.

Így esett a választásom a @splattransform-gh -nél fellelhető `splat-transform` nevű parancssori programra, ami pont arra jó, hogy GS modelleket lehet vele parancssorból konvertálni. A dokumentációja alapján támogatja a glTF formátumot is @GLTFExtSuperSplatDoc.

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
<compositoreffect-fejezet>

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
<kiterjedes-iranyai-trafo-fejezet>

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
<automata-objektum-megtalalas-fejezet>

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
<melyseghelyes-osszekombinalas-fejezet>

A motor által generált és megjelenített háromszöghálós modellek, például a @depth_combination. ábrán látható két darab kapszula, és az általunk menedzselt kóddal megjelenített Gauss-i modellek, például a @depth_combination. ábrán látható vonat, sínek, autó és fák teljesen külön csővezeték által vannak generálva. Ez két teljes kép a képernyőre, egyik a háromszöghálós modelleket tartalmazza, a másik a Gauss-i modelleket.

Ahhoz, hogy ezt az elvárt módon meg tudjuk jeleníteni, össze kell a két képet kombinálni, a mélység alapján. A Godot a saját maga által számított háromszöghálós modelleket tartalmazó kép mélységértékeit tudja, nekünk a saját kódban számolt kép mélységértékeit kell előállítanunk. Első körben, hogyha az átlátszóságot nem vesszük figyelembe, mindkét kép minden pixeléhez eltárolunk egy mélységértéket, és azt a színt jelenítjük meg, amelyik kép azon a pixelen a kamerához közelebb van.

#figure(
  image("pictures/depth_combination.png")
  , caption: [A mélység kombinálásának tesztelése a vonatos jelenettel és kapszulákkal]
) <depth_combination>

A @depth_combination. ábrán láthatóak a korábbról ismert repülő alakú kapszulák. Ezek az útvonalat követve mozogtak is, így lehetővé téve különböző mélységértékek tesztelését. A képernyőkép készítésekor még hiányzott egy transzformációs lépés ( `0..1` és `-1..1` range között), így a határ, ahol a két kép kombinálásának határa van, eltolódott, és a kapszulák irreálisan nagynak tűnnek. Ez később javítva lett.

Ennek a feladatnak a programkódban történő megvalósítása már komplexebb volt. Először is a projekciót végző shader kódból továbbítani kellett a kamerától vett távolságot, ehhez a következő lett a helyes kód:

```glsl
	data.pos_z = (ndc_pos.z + 1.0) * 0.5;
```

Ezután a renderelést végző shader kódon kellett átvezetni az értéket, miközben azt is meghatározzuk, hogy milyen módon legyen több paca mélységértéke összekombinálva. Első ösztönre a kamerához legközelebbi megtartása jutna az ember eszébe, de ez GS modellek esetén nem fog jó eredményre vezetni, mivel sokszor tartalmaznak nagyon nagy, nagyon átlátszó pacákat, amik potenciálisan sokkal közelebb vannak a kamerához, mint a ténylegesen fontos, látható splat-ok. Emiatt egy olyan számításra esett a választásom, ami a már meglevő színszámításhoz hasonlóan egy az átlátszósággal súlyozott átlagát számítja ki az adott pixelen látható splat-ok mélységértékeinek. Ehhez két változót akkumulálunk: a súlyozott átlagot, illetve a súlyok összegét. Ez azért szükséges, hogy a végeredményként a kettő hányadosa normalizálja a mélység értékét a megfelelő range-be.

A renderer shaderkód több revízión átment, de logikailag végig a @depthblending_glslkod. kódrészleten látható megoldás maradt a mélység kinyerésének mószere. Később az átlátszóság megjavításával más-más értékekhez lett a mélység hozzácsatolva: a @depthblending_glslkod. kódrészleten a színhez, 4. koordinátaként csatolás látható (az alpha helyett), de más verziókban volt paddelve, vagy az újravilágítást is támogató kódbázisokban a normál értékhez csatolva.

#figure(```glsl
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
  float final_depth = total_weight > 0.0 ? 
                      (weighted_depth / total_weight) : 0.0;
  imageStore(rasterized_image, ivec2(image_pos), 
             vec4(blended_color + heatmap_color, final_depth));
  ...
```, caption: [A render GLSL script továbbítja a mélységértéket]
) <depthblending_glslkod>

Ennek a kódnak a megértése során eleinte problémákba ütköztem, mivel a kód workgrouponként párhuzamosan tölti be az adatokat, majd párhuzamosan dolgozza őket fel, viszont az adott szál által betöltött adat nem feltétlenül egyezik meg a később általa feldolgozott adatokkal. Így eleinte változatos, nehezen értelmezhető workgroup-határok mentén éles vonalakkal rendelkező grafikai glitch-eim voltak, mielőtt a logikát és a problémát megértettem. Emiatt van szükség a @depthblending_glslkod. kódrészleten a shared bufferre.

Miután a mélységérték eljut a generált képbe, azt könnyen át tudjuk adni a Godot-nak, például a teljes képernyős quad-on található spatial shader-ben, a @depthforwarding_fragmentgds. kódrészleten látható módon.

#figure(```glsl
void fragment() {
	ALBEDO = srgb_to_linear(texture(render_texture, SCREEN_UV).rgb);
	DEPTH = texture(render_texture, SCREEN_UV).a;
}
```, caption: [A spatial shader fragment része továbbítja a mélységértéket]
) <depthforwarding_fragmentgds>

=== Szín normalizálása

Itt említeném meg, hogy a fentebb használt normalizáció a színnél is szükséges matematikailag. Az eredeti, @OriginalGGSVFejezet. fejezetbeli kódbázis sohasem dolgozott a teljes generált képet érintő átlátszósággal, így helyes volt az, hogy a fekete háttérhez akkumulálja a színeket, majd azt jeleníti meg. Mi viszont nem tudjuk, hogy milyen szín van a félig átlátszó modell szélei mögött, így amennyiben nem normalizáljuk a színt, a nagyon átlátszó helyek inkorrektül sötétek lesznek. Az átlátszóság alkalmazásával már bele van számolva az, ami az eredeti megjelenítőben a normalizáció nemalkalmazásával, azaz feketével blendeléssel került megoldásra.

#figure(
  image("pictures/color_normalization_difference.png")
  , caption: [A szín is normalizálásra szorulna, de a különbség nem nagy]
) <color_normalization_difference>

A @color_normalization_difference. ábrán látható az ez által okozott különbség: a bal oldali ábra a normalizálás nélküli, míg a jobb oldali ábra a normalizációt tartalmazó shaderkód eredménye. Sajnos a PDF, illetve a papír formátum sem támogatja a GIF vagy a videó formátumokat széleskörűen, így be kell érnünk a két kép egymás mellett való elhelyezésével. Én a képek között váltogatva egyértelműen látom a különbséget: apró, de észrevehető. A bonsai modell leveleinek legszélét érdemes tüzetesen megvizsgálni: a horizont felett csökkent, világosodott a sötét körvonal az építőelemek széleinél, míg a horizont alatt is, hasonlóan, picit nőtt a világos rész terjedelme. Mindenesetre a különbség a legtöbb modellnél nagyon nehezen észrevehető.

== Plugin készítése
<plugin-keszitese-fejezet>

Az eddigi, kiindulási projekt egy sima Godot projekt volt, egy fő jelenettel, ami tartalmazta többek között a megjelenítéshez szükséges node-okat. Ezt a projektet, és ezt a jelenetet kellett megnyitni a GS modellek megjelenítéséhez. Mi viszont egy általánosan használható, könnyen integrálható megoldást szeretnénk csinálni.

A Godot lehetőséget biztosít pluginok készítésére, amiket könnyen, az `addons` mappába helyezéssel be lehet illeszteni bármilyen projektbe, majd az editorban pár kattintással aktiválni-deaktiválni lehet. Ezt nem túl nehéz létrehozni, egy config fájl, meg egy `EditorPlugin` leszármazott script szükséges hozzá #footnote[https://docs.godotengine.org/en/stable/tutorials/plugins/editor/making_plugins.html].

A mi célunkhoz továbbá át kell másolni a szükséges fájlokat az addon mappájába, a nem szükségeseket pedig kiszűrni. Külön meg kell említeni a fő jelenetet, mivel azt nem lehet 1:1-ben betenni úgy, hogy minden egyéb jelenet esetén megjelenjen. A @automatic_node_discovery. ábrán látható a jelenet egy verziója. Itt található például a `RenderedImage` nevű node, ami egy `QuadMesh`-t tartalmazó és megjelenítő `MeshInstance3D` . Ez a node lényegében az egyetlen fontos a megjelenítéshez a jelenetből, minden más létrehozását a plugin felhasználójára, és a tényleges aktuális jelenetre bízhatunk.

A Godot támogat egy autoload nevű funkciót #footnote[https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html], ami pont ilyen esetekre jó. A projektbeállításokban (vagy akár a plugin inicializáló scriptjében) be lehet állítani egy vagy több scriptet, vagy akár teljes jelenetet, ami az éppen aktuális jelenet gyökér node-jának testvéreként, a `root` nevű, `Window` típusú igazi gyökér gyerekeként példányosodik. Ez egyébként megmarad jelenetváltások között is. Az így kialakuló hierarchia látható például a @lathatosag_lathato\-@lathatosag_nemlathato. ábrákon. Az editorban látható Remote illetve Local kapcsolóval lehetséges váltani a futó alkalmazás jelentfája, és az editorban levő, mentett jelenetfa között.

Ez a singletonos architektúra alapvetően nem garantál két hasznos dolgot, ami a korábbi, közvetlen jelenetben szereplő `RenderedImage` esetén nem volt kérdés: egyrészt azt, hogy a teljes képernyős quad ( `QuadMesh` ) ténylegesen meg is fog-e jelenni, és helyesen lesz-e a mélység összekombinálva, másrészt pedig azt, hogy az editorban is megjelenjen, hogy a modelleket futtatás nélkül, szerkesztés közben lehessen módosítani. Szerencsére mindkét kétes feature probléma nélkül működött, miután átminősítettem a node-ot autoload singletonná.

Az utóbbi azért lehetséges, mert a Godot saját magát használja megjelenítésre, illetve a `@tool` annotációval ellátott scriptek könnyen képesek futni az editorban. Vélhetően a motor jól átgondolt architektúrájának köszönhetően így még az autoload tool is képes futni az editorban, sőt, még az autoload scripttel ellátott `MeshInstance3D` is látható, az editorban is.

== Pull vagy Push modell
<pull-vagy-push-fejezet>

Az @automata-objektum-megtalalas-fejezet. fejezetben bemutatott objektumösszegyűjtés egy jó kiindulópont volt, de több szempontból nem optimális. Egyrészt csúnya a kód, ami összegyűjti a függvénynév alapján a node-okat, másrészt felelősség szerint nem a legjobb konstrukció, ha mindent a gyökér node végez, harmadrészt nehéz a dinamikus láthatóságot implementálni.

Ezek az indokok miatt a `RenderedImage` által végzett pull helyett áttértem a GS pozíciójáért felelős node push megoldására. Ezzel a módszerrel a `SplatMesh` (később `SplatCloud3D`) maga regisztrálhat a kirajzolásra, és jelentkezhet le róla.

=== Dinamikus láthatóság

Ez a változatás azt is könnyűvé tette, hogy amennyiben a node láthatósága változik, akkor leregisztráljon a megjelenésről, vagy visszaregisztráljon rá, és ezzel eltűnjön ténylegesen a jelenetből, vagy megjelenjen benne. Ez része annak a törekvésnek, hogy a pontfelhős modellek az editorba, illetve a játékba is jobban legyenek integrálva, azaz az editorba épített feature-ök (mint például a láthatóság) úgy működjenek rajtuk, mint ahogy a felhasználók várják, és az a motor többi részétől megszokott. A plüssmaci a @lathatosag_lathato. ábrához képest a @lathatosag_nemlathato. ábrán láthatóan nem látható.

#figure(
  image("pictures/lathatosag_lathato.png")
  , caption: [Látható a plüssmaci]
) <lathatosag_lathato>


#figure(
  image("pictures/lathatosag_nemlathato.png")
  , caption: [Nem látható a plüssmaci]
) <lathatosag_nemlathato>

Ennek a módosításnak a segítségével már nem szükséges minden modellcserénél, vagy új modell hozzáadásakor lefuttatni a pull scriptet, ami a gyakorlatban azt jelenti, hogy nem kell bezárni, és újranyitni az egész jelenetet, hanem az editorban is egy modellcserénél, node törlésnél, vagy hozzáadásnál automatán elvégzi a rendszer a frissítést. Ez nagyon sokat lendített az editor használhatóságán.

Hozzá kell azért tenni, hogy ez a megoldás még nem volt a legcélravezetőbb: minden láthatóságváltoztatáskor, illetve modell hozzáadáskor, cserekor és törléskor a teljes éppen aktuálisan látható splatos adatot feltöltöttük a GPU-ra. Ez azért volt, mert miután a `RenderedImage` singleton megkapta a változtatási kérelmet, nem tudott mást csinálni, minthogy egy teljesen új rasterizer példányt hoz létre, a megfelelő modellekkel. Ehhez képest egy másik, precízebb módszer a @igazi_dinamikus_lathatosag-fejezet. fejezetben kerül bemutatásra.

=== Kifinomultabb dinamikus láthatóság
<igazi_dinamikus_lathatosag-fejezet>

A dinamikus láthatóságváltoztatásra egy kifinomultabb megoldást ad például, ha a transzformációs mátrixhoz hasonlóan továbbítunk egy bool értéket a GPU-ra, és az határozza meg, hogy az adott modellhez tartozó pacák kirajzolásra kerülnek-e ténylegesen, vagy sem. Így az adat végig ott marad a GPU-n, akkor is, amikor a modell nem látható, de a kirajzolás korai fázisában explicit eldobja az adatot a grafikus processzor. Így egy potenciális láthatóvá tétel esetén a mozgatáshoz hasonlóan instant ki tudjuk rajzolni a modellt a megfelelő helyre, nincs szükség nagy adat mozgatására.

Ezt a módszert az @ikon-dinlat-instancing-pr-fejezet. fejezetben bemutatott pull request, illetve előtte az ott bemutatott másik kódbázis letesztelésének keretében implementáltam. A változtatás nem volt nehéz, de több fájlon át kellett propagálni a láthatóság értékét, ami végül a GPU-ra feltöltés során a transzformációs mátrix egyik nem használt értékének a helyére lett beszuszakolva. Ez alapján az érték alapján a shader el tudja dobni a splat-ot, ha szükséges, és akkor a modell nem fog látszani. Az ezt megvalósító GLSL kód a @realvisibility_glsl. blokkban látható.

#figure(```glsl
float is_visible = model_matrix[0][3];
if (is_visible < 0.5) return;
model_matrix[0][3] = 0.0;
```, caption: [A projekciós shader eldobja a nem látható splat-okat]
) <realvisibility_glsl>

== Elsőosztályú polgárok

Az előbbiekben már javítottuk az editorintegrációt a láthatóság figyelembe vételével, ebben a fejezetben még pár a használatot javító, kellemesebbé tevő fejlesztést mutatok be.

=== Editor ikonok
<editor-ikonok-fejezet>

Az editorban szinte minden node-leszármazottnak, illetve beépített erőforrásnak (resource) saját SVG ikonja van, így sokat javíthatunk a beépítettség érzésén, ha hozzáadunk a saját osztályainkhoz is ikonokat, amiket az editor használni tud. A `Node3D`-leszármazottak ikonjai mind `#fc7f7f` (halványpiros) színűek, míg a `Resource`-leszármazottakéi mind `#ffca5f` (citromsárga) színűek. Ez alapján a @tablazat_teszt. táblázatban megjelölt ikonokat párosítottam a saját osztályaimhoz, ami így végeredményként a @editor_ikonok. ábrán látható eredményt adja, ha kijelöljük az egyik `SplatCloud3D` node-ot, és beleteszünk egy `SplatCloudData` resource-t.

#figure(table(columns:2,
  [SplatCloud3D], [SplatCloudData], 
  [Piros, átfedő pacák], [Sárga, kisebb sugarú pacák]
), caption: [Saját osztályok ikonjai]
) <tablazat_teszt>

#figure(
  image("pictures/editor_ikonok.png", width: 80%)
  , caption: [Az új ikonok megjelennek az inspectorban]
) <editor_ikonok>

Viszont először hiába írtam be a pontos színkódot, arra lettem figyelmes, hogy egy árnyalattal mégis el vannak rontva az ikonjaim. Kis kutatás után találtam rá, hogy az ikon importálásánál van két flag, amit be kell kapcsolni, hogy a skálázás, és a témázás az elvárt módon működjön, és így a szín automatikusan felveszi az editor kinézetének megfelelő színt, pont, mint a többi beépített ikon #footnote[https://docs.godotengine.org/en/stable/engine_details/editor/creating_icons.html].

Az ikonok alkalmazása a kód oldaláról triviális volt, a @splatcloud3d-icon-gds\-@splatclouddata-icon-gds. kódrészleten láthatóan.

#figure(```py
@tool
@icon("res://addons/gsplat-nodes/icons/splat_cloud_3d.svg")
class_name SplatCloud3D extends Node3D
```, caption: [A `SplatCloud3D` osztály ikont kap]
) <splatcloud3d-icon-gds>

#figure(```py
@icon("res://addons/gsplat-nodes/icons/splat_cloud_data.svg")
class_name SplatCloudData extends Resource
```, caption: [A `SplatCloudData` osztály is ikont kap]
) <splatclouddata-icon-gds>

Egy problémás helyet az ikonnak viszont szükséges megemlíteni: a FileSystem dock-ban a Godot verziótól függően nem mindig jelenik meg az ikon, néha a sima `Resource` osztály ikonja látszik. Ez annak köszönhető, hogy performance okokból, és finomítás céljából módosították az implementációt #footnote[https://github.com/godotengine/godot/pull/77932] többször #footnote[https://github.com/godotengine/godot/issues/93874], ami így most jelenleg az én beállításaimmal nem működik. Ennek lehet, hogy a nem beépített kiterjesztés (például `.ply`) az oka #footnote[https://github.com/godotengine/godot/issues/94964]. Az ikon hiánya látható a @import_ply. ábrán is.

=== Betöltés, és tárolt adat szétcsatolása

Az eddigi kódban a `PlyFile` nevű osztály volt felelős mind a fájlformátum betöltéséért, mind a betöltött adat tárolásáért. Ezt több praktikus szempontból célszerű megváltoztatni.

Egyrészt, hogyha később többféle fájlformátumot szeretnénk implementálni, akkor a formátumbetöltésre külön logika kell, viszont lehetőség szerint a tárolt adatot, belső reprezentációt már jó, ha ugyanaz az osztály kezeli minden formátum esetén. Ezt a Godot többi része is így kezeli, és a fájl importálás technikáját elérhetővé is teszi a felhasználók számára, így a pluginnal könnyen tudunk új importereket regisztrálni.

Másrészt pedig, hogyha eddig exportált build-ben szerettünk volna pontfelhős modelleket megjeleníteni, akkor explicit minden projektben meg kellett volna mondani az editornak, hogy a `.ply` fájlokat tegye bele az exportált build-be, és így is minden alkalommal be kell parszolni a fájlt a megnyitáskor. Hogyha egy `Resource` leszármazottba az engine importálóját használva betöltjük a pontfelhős modellt még az editor használata közben, akkor a már betöltött formátum automatikusan mentésre kerül például exportáláskor. És egyéb, kényelmi feature-öket is lehetővé tesz, mint a beépített import fül használata, illetve drag-n-drop a fájlrendszer fülről az inspectorba.

A felelőség szétszedése nem volt túl bonyolult, az explicit fájl parszolásért felelős rész átkerült az új PLY importerbe, míg a többi rész: az adattagok, a @egyszerre-tobb-pontfelho-fejezet. fejezetben említett merge-elés, illetve a GPU-kompatibilis reprezentáció készítése maradtak az eredeti fájlban, ami így az @tablazat_teszt. táblázatban is említett `SplatCloudData` névre lett átkeresztelve.

A @import_ply. ábrán látható is az importer felülete, amihez az adatokat az importer script-ben getterek írásával lehet megadni, mint például amik a @importer_gettek_gds. kódblokkban láthatóak. Ezután a @import_ply. ábrán a FileSystem fülről a fájlnevet lehetséges drag-n-droppolni a @editor_ikonok. ábrán szereplő Splat Data attribútum értékéhez, így nagyban megkönnyítve a node és a resource közötti kapcsolat létrehozását.

#figure(
  image("pictures/import_ply.png", width: 50%)
  , caption: [A `ply` fájl importálása a motor felületét használja]
) <import_ply>


#figure(```py
func _get_importer_name() -> String:
	return "gsplat.ply.importer"

func _get_visible_name() -> String:
	return "Gaussian Splat (.ply)"

func _get_recognized_extensions() -> PackedStringArray:
	return ["ply"]
```, caption: [A `ply` importer gettereinek egy része]
) <importer_gettek_gds>



== AMD bug kijavítása
<amd-bug-fejezet>

A különböző számítógépeken való tesztelések során figyelmes lettem egy AMD hardveren történő hibára. Ezt az eredeti megjelenítő által használt VulkanRadixSort @vulkan-radix-sort-gh könyvtárra vezettem vissza, és az eltérő subgroup méret, illetve a kevésbé engedékeny szabványkövetés okozhatta. A hibát én is kijavítottam, és közben láttam azt is, hogy upstream a VulkanRadixSort-nál is kijavították már #footnote[https://github.com/jaesung-cs/vulkan_radix_sort/issues/7]. Viszont a @OriginalGGSVFejezet. fejezetben írt megjelenítőt, amelyikre a kódot alapoztam, már 2 éve nem frissítették egyáltalán, így ez a fix se került bele. Van viszont egy nyitott issue náluk is, ami pont ezt a problémát írja le AMD hardveren @amd-bug-upsteam-issue, így megjelöltem nekik a VulkanRadixSort javítást, illetve a sajátomat is, hogy annál az issue-nál is meg legyen jelölve, hogy mi okozza a problémát.

== CompositorEffect-es megoldás vizsgálata
<compositoreffect-onallomunka-fejezet>

A @compositoreffect-fejezet. fejezetben bemutatott másik fajta módszer a végleges kép megjelenítésére szintén egy járható út, és a @kollab-onallomunka-fejezet. fejezetbeli kollaboráció során nekem is volt szerencsém ezzel a megoldással dolgozni. Az architektúra annyiban különbözik, hogy nincs szükség az autoload singleton-ra, hanem helyette a jelenetbe bele kell tenni egy `WorldEnvironment` node-ot, amiben létre kell hozni egy `Compositor`-t, és annak kell hozzáadni `CompositorEffect`-ként a saját scriptünket.

Ez a plugin felhasználójának szemszögéből minimálisan több setup-ot igényel, cserébe viszont az architektúra jobb: nem GDScript-ből kell manuálisan hívni az újrarenderelést minden alkalommal, nem kell nekünk kezelnünk a textúrát, és esetleges ablakátméretezés esetén megoldani, hogy a megfelelő méretű legyen, illetve jóval natívabban tudjuk a képek összekombinálását is végezni.

== Instancing
<instancing-fejezet>

Az instancing fogalma azt jelenti, hogy ugyanazt a modellt többször rajzoljuk ki, ami így hatékonyabb, mintha egyesével, külön-külön rajzolnánk ki ugyanazt a modellt #footnote[https://en.wikipedia.org/wiki/Geometry_instancing]. A mi esetünkben ezt úgy lehet értelmezni, hogy ha több példánya van a jelenetben ugyanannak a modellnek, akkor nem szeretnénk a teljes modellt többször feltölteni a GPU-ra.

Ennek a feladatnak az implementációja a @igazi_dinamikus_lathatosag-fejezet. fejezetben bemutatott, dinamikus láthatóság mellett került implementálásra, a @kollab-onallomunka-fejezet. fejezetben bemutatott kódbázisban.

Mind az a kódbázis, mind a korábbiakban bemutatott, úgy oldja meg eddig a kirajzolást, hogy minden egyes paca kap egy extra ID-t, ami azt mondja meg, hogy a pacát a transzformációs mátrixok tömbjében az ID-edik mátrixával kell eltranszformálni a modelltranszformációkor. Ez oldja meg azt, hogy a modellek képesek legyenek máshogy mozogni.

#figure(
  image("pictures/instancing_figure.pdf")
  , caption: [Magyarázó ábra az instancingről]
) <instancing_figure>

Ehelyett, amint azt a @instancing_figure. ábra is szemlélteti, hogyha feltöltünk még egy tömböt, amiben pacák és transzformok sorszámait tároljuk, akkor sok helyet meg tudunk spórolni. Ugyanis eddig, ha egy modell többször szerepelt a jelenetben, akkor a teljes adatát duplikáltan kellett feltölteni a GPU-ra, mivel egy paca adatát csak egyszer tudtuk kirajzolni. Ezt az indirekciót beletéve viszont képesek vagyunk azt megoldani, hogy egy pacát több, különböző transzformmal is ki tudjunk rajzolni.

A @instancing_figure. ábrán szereplő példán részletesebben bemutatva: van egy modellünk, ami 4 pacát tartalmaz. A valóságban természetesen százezres nagyságrendű is lehet ez a szám, így egy modell által foglalt hely gyakran eléri például az 50MB-ot is. Ezt szeretnénk kirajzolni kétszer, két objektumként. Ezeknek van két külön transzformja, ami a pozíciójukat, elforgatásukat és skálázásukat meghatározza. Instancing nélkül a teljes modell adatát (mind a 4 pacát) duplikálnunk kell, mert így tudunk csak egy-egy pacát többször kirajzolni. Instancing esetén viszont a köztes táblázatnak lesz csak 8 sora, ami sokkal kevesebb helyet foglal (2 int, 60 float helyett), és többször tudunk referálni a pacák tömbjének elemeire. Az instance-es táblázat jobb oldalától pedig a rendszer ugyanúgy viselkedik, mint az előző esetben, kikeresve a helyes transzformot.

=== Instancing hatásának mérése

A munka sikerességét leginkább a memóriahasználattal lehet ellenőrizni. Ennek végrehajtásához a tesztjelenethez hozzáadtam 10 db autót a @instancingelott\-@instancingutan. ábrán láthatóan, és megmértem a memóriahasználatot az instancing előtti verzióval, és az instancinget használó verzióval. A méréshez az `nvidia-smi` parancsot használtam, mivel a desktopomban NVIDIA grafikus kártya van.

A mérés azt mutatta meg, hogy az instancing láthatóan jelentősen javította a memóriahasználatot: friss indítás után a @instancingelott. ábrán 1207MiB-t használt az instancing előtti állapot, míg a @instancingutan. ábrán 818MiB-t az instancinget használó állapot.

#figure(
  image("pictures/instancing_elott.png")
  , caption: [Instancing nélküli memóriahasználat]
) <instancingelott>

#figure(
  image("pictures/instancing_utan.png")
  , caption: [Instancing utáni memóriahasználat]
) <instancingutan>

Többszöri tesztelést végrehajtva ugyanezzel a példajelenettel, editor nélküli, illetve editorból történő indítással azt az eredményt kaptam, hogy a memóriahasználat ilyen kis méretű memóriánál nehezebben határozható meg pontosan: néha lényegében ugyanannyi volt mindkét implementációnak a memórialábnyoma. Ezt párosítva azzal, hogy az autó modell mindössze 8MB, így a 10 autó által nyerhető memória elméletileg is kevesebb, mint 72MB, illetve a memória-allokációról szóló előzetes tudásom alapján az a gyanúm van, hogy a memóriahasználat adagonként bővül, és ez okozza a mérés pontatlanságát. De a fentebbi eredmények editor nélküli indítás során mindenesetre konzisztensen reprodukálhatóak, így az implementáció működése, és a kisebb memóriahasználat igazolva van.

== Újravilágíthatóság implementálása
<relightolas-sajatmunka-fejezet>

A @relightolhatosag-bemutatas-fejezet. fejezetben bemutatott újravilágítás, újraszínezés technológiája egy komplex téma. Mi ennek a problémának azt a részhalmazát fogjuk megoldani, ami a @mesh2splat-program-fejezet. fejezetben bemutatott program kimenetét tudja jól megjeleníteni, újrafényezni. A bemeneti fájlformátum tehát a @religtholhato-ply-format. fejezetben tárgyalt PLY formátum lesz.

Az implementáció lehetőségeinek felmérésekor többféle megoldás is célravezetőnek tűnt, mindkettő a saját erősségeivel és gyengeségeivel. Végül arra jutottam, hogy mindkettőt megvalósítom, összehasonlítási céllal.

#figure(
  image("pictures/relightolhato_mindketshaded.png")
  , caption: [Suzanne, a Blender majom megvilágítva általunk, illetve Godot által]
) <relightolhato_mindketshaded>

=== Saját fényszámítással
<relightolas-sajatszamitas-fejezet>

Az első lehetőség az, hogy mi adjuk át manuálisan a beszámítandó fényforrásokat a shader-nek, és a mi shaderünk számolja a színeket a megadott PBR-, illetve fényparaméterekből. A prototípust úgy csináltam, hogy egy irányfényforrást tudunk átadni. Ennek a módszernek a hátránya a manuális fényforrás-összegyűjtés, illetve az árnyalás eltérő lehet a többi, motor által árnyalt modell árnyalásától. Előnye viszont, hogy működik a @compositoreffect-fejezet. fejezetben tagalt CompositorEffect-es megoldással, és az átlátszóság teljesen normálisan értelmezhető: mivel a pacák árnyalását mi számoljuk ki, ezért semmi nem akadályoz meg minket abban, hogy egy pixelen több paca végső színét is kiszámoljuk, majd az eddigi blendelést használva az árnyalás után kombináljuk össze őket. Ezt a módszert a kompozitoreffektes kódbázishoz implementáltam.

A kép eredménye a @relightolhato_mindketshaded. ábrán a bal oldalon látható. Az irányfényforrás általi megvilágítás működik, viszont a jobb oldali ábrához képest azért láthatóan eltér egy picit a sötét részeken a sötétség mértéke a natív árnyalástól, ami a leginkább a henger sötét oldalán látszik. Ezen a saját árnyalás finomhangolásával lehetne segíteni, de végletként nem volna szerencsés a Godot teljes árnyalását újraimplementálni.

=== A Godot fényszámításával
<godot-relighting-fejezet>

A másik megoldási lehetőség a Godot deferred shading-jének a használata, azaz átadni a Godot-nak a PBR tulajdonságokat textúrákban, hogy ő árnyalja a modellünket, pontosan úgy, ahogyan a jelenet többi részét árnyalná. Ehhez ő rendelkezik a jelenet pontos fényeivel, ami a motor belső reprezentációja, gyorsítótárazása miatt az előző módszer esetén számunkra nem volt elérhető a shader-ből.

Ennek a módszernek viszont hátránya az, hogy pixelenként csak egyetlen árnyalást tudunk végrehajtani, ugyanis egy adag PBR tulajdonságot tudunk csak átadni a motornak. Emiatt egyáltalán nem is tudunk félig átlátszó pacákat kezelni, mivel akkor látszódna mögötte ugyanazon a pixelen egy másik paca, amit szintén árnyalni kéne. Ez elég fájó a Gaussian Splatting esetén, mivel a pacák átlátszósága az egyik fő attrakciója a módszernek. Az pedig nem igazán fog használható eredményt adni, ha az anyagtulajdonságokat blendeljük az átlátszóság szerint, majd azt adjuk át árnyalni.

Egy másik hátrány pedig, hogy a Godot-nak az árnyaláshoz csak a fullscreen quad-os megoldással lehet átadni az anyagtulajdonságokat (ORM: occlusion, roughness, metallic), és a normálvektorokat, így azt a kódbázist kell előszedni a módszer teszteléséhez, amelyik azt a megjelenítést használja.

A kódbázis elővétele után sürgősen szükséges volt kijavítani egy bugot, ami idő közben nagyon problémássá vált: mi hívjuk explicit a render thread-en a kirajzolást, és ez egyből megtörténik a `_process` callback hívása során, a @renderthread_rasterize_gds. kódrészleten látható módon. Ez viszont akkor is meghívódott, amikor az ablak nem volt fókuszban, vagy éppen egyébként a jelenet többi része nem rajzolódott újra, így "felgyűltek" a frissítések. Ez pedig azt okozta, hogy következő alkalommal, amikor újra mozgatni szerette volna a képet az ember, akkor egy nagy szaggatásnak lehetett a tanúja, mielőtt a rendszer életre kelt. Rosszabb esetekben az egész motort is magával vitte a program. A megoldás az lett, hogy a kódrészleten is láthatóan feltételhez kötöttük a raszterizáció hívását, és csak akkor hívjuk meg a frissítést, ha tényleg történt valami változás.

#figure(```py
if has_camera_updated or transforms_changed or is_loading:
  RenderingServer.call_on_render_thread(rasterizer.rasterize)
```, caption: [A raszterizáció hívása a `_process`-ből]
) <renderthread_rasterize_gds>

Miután ezt megjavítottuk, rá lehet térni az újravilágítás implementálására. Az előzőhöz hasonlóan úgy kell módosítani a PLY importert, hogy az eredeti, 60-64 érték helyett a 20 új értéket keresse, és tegye be a belső reprezentációba. Ennek megfelelően kell a belső reprezentációkat is módosítani, mind a CPU-n ( `SplatCloudData` ), mind a GPU-n (projection és render shader-ök). Létre kell hozni, és helyesen bekötni a szükséges buffereket, illetve a gömbi harmonikusos színkalkulációt lecserélni a paraméterek átadására a 3 különböző textúrába. Végül a teljes képernyős quad-ra helyezett spatial shader kapja meg az anyagtulajdonságokat, és adja tovább a játékmotornak, aki innentől kezeli az árnyalást.

Az eredmény a @relightolhato_mindketshaded. ábra jobb oldalán látható, és tényleg sokkal jobban beleillik a jelenetbe, mint az általunk árnyalt Suzanne. Megjegyzendő, hogy a Mesh2Splat-tal konvertált modellekben amúgy sem jut sok szerephez a pacák átlátszósága, egyszerű modelleknél legalábbis, így a módszer ezzel kapcsolatos hiányossága az ábrán nem okoz látható problémát.


==== Javítás nem irányfény esetére

Mivel az engine számolja az árnyalást, így elméletileg ingyen támogatást kapunk az egyéb, beépített fényforrások fényének árnyalására is. Ehhez viszont az irányfényforráshoz képest még egy dolgot át kell adjunk a motornak, méghozzá a világbeli pozícióját a modellnek. Erre érthetően szüksége van, mivel például a spotlight fényereje függ a modell spotlighthoz képesti irányától, és távolságától is, ezeket pedig a pozíció alapján tudja a motor meghatározni. Az irányfény esetén nem volt nagyon fontos a világbeli pozíció, mivel az irányfény (árnyéktól, egyéb effektektől eltekintve, ezek nem képezik részét a projektnek) minden pontban ugyanannyira világít meg objektumokat, csak a felület normálvektora számít.

#figure(
  image("pictures/relightolhato_spotlight.png")
  , caption: [Suzanne, a Blender majom megvilágítva Godot által egy spotlight-tal]
) <relightolhato_spotlight>

A @relightolhato_spotlight. ábrán látható a megvilágítás eredménye, bal oldalon a helytelen világbeli pozíció átadásával, míg a jobb oldalon a helyes pozícióval. A javítás pedig inkább egy workaround, mint egy tökéletes megoldás: sajnos a Godot nem fogadja el a koordinátákat a fragment shader-ben, így muszáj a vertex shadert használni ehhez. Viszont a mi modellünk nem háromszögháló alapú, hanem lényegében ebből a szempontból egy téglalap, így az az ötlet, hogy osszuk fel a téglalapot például 128x128 kis téglalapra, majd a csúcspontokat "terítsük rá" a GS jelenetre, mint egy lepedőt. Így az adott pixeleken a világbeli koordináta elég közel lesz az adott GS modell tényleges világbeli koordinátájához, és az árnyalás helyesen tud működni. Néhol, a modell határánál lehet látni némi pontatlanságot, de összességében a módszer minőségéhez képest a végeredmény teljesen rendben van.

==== Együttes megjelenítés gömbi harmonikusos modellekkel
<egyuttes-megjelenites-fejezet>

Az előző fejezetben a gömbi harmonikusok betöltését, számítását tulajdonképpen lecseréltük a PBR folyamatra. Viszont egy plugin akkor sokkal könnyebben használható, hogyha ugyanazzal a kódbázissal képes újravilágítható modelleket, és gömbi harmonikusos modelleket is megjeleníteni. Sőt, esetleg még egyszerre is képes mindkét modellfajtát megjeleníteni.

Ezt úgy volt célom megvalósítani, hogy merge-elem az új módosítások branch-ét, és a módosítások előtti változatét, ami tartalmazza a közben implementált, @gltf-beolvasas-fejezet. fejezetben bemutatott GLTF formátum betöltését.

Ez nem egy egyszerű merge-elési folyamat volt, mivel a gömbi harmonikusok működéséhez meg kellett tartani azt a kódrészletet, amihez az egyik branch nem nyúlt, a másik pedig kitörölte. Összességében viszont mégis viszonylag könnyen ment. Az adat formátumának kérdésére a megoldás pedig az lett, hogy mindkét halmaz attribútumot elmentjük. Ez összesen 64 float, a fájlban nem található értékeket pedig alapértelmezett értékekkel töltjük fel. A shader ezek alapján el tudja végezni mindkét árnyalást, aminek az eredménye a @relightable_and_sh_together. ábrán látható is.

#figure(
  image("pictures/relightable_and_sh_together.png")
  , caption: [Az újravilágítható Suzanne és a gömbi harmonikusos GLB bonsai egy kódbázisból van kirajzolva]
) <relightable_and_sh_together>

== Fájlformátumok implementálása

=== SPLAT adatfájl adatainak beolvasása

A `.ply` formátumban tárolt GS modellek paraméterei nem mindig ugyanazok, és ennek kezelése fentebb is fontos szerepet játszott, például a @relightolas-sajatmunka-fejezet. fejezetben. Alább azt mutatom be, hogy a @splat-formatum-fejezet. fejezet-beli `.splat` fájlok adatait hogyan tudjuk beolvasni.

Ennek a motivációja az, hogy a projekt elején többféle modellt szerettem volna megjeleníteni, például a @lathatosag_lathato. ábrán látható plüssmacit, ezek közül pár viszont ebben a formátumban volt elérhető.

A formátumot magát nem szükséges nekünk parszolni, mivel a @supersplat-fejezet. fejezetben bemutatott SuperSplat editorja képes konvertálni `.splat` formátumból `.ply` fájllá. Szükséges viszont a `.ply` beolvasást robosztusabbá tenni, mivel a konvertált fájl, és az eddigi, beolvasott `.ply` fájlok formátuma nem teljesen egyezik meg.

Az eltérés két formában ölt testet: egyrészt a tulajdonságok közül sok hiányzik, másrészt pedig a sorrendjük nem egyezik meg a korábban megszokottal. Az örökölt beolvasófüggvény eddig egyikre sincs felkészítve.

#figure(```
ply
format binary_little_endian 1.0
element vertex 116722
property float x
property float y
property float z
property float opacity
property float rot_0
property float rot_1
property float rot_2
property float rot_3
property float f_dc_0
property float f_dc_1
property float f_dc_2
property float scale_0
property float scale_1
property float scale_2
end_header
```, caption: [A konverzió eredményeként kapott `.ply` formátumú plüssmaci fejléce]
) <ply_formatum_splatbol_txt>

#figure(```
x, y, z, nx, ny, nz, f_dc_0, f_dc_1, f_dc_2, f_rest_0, f_rest_1, f_rest_2, f_rest_3, f_rest_4, f_rest_5, f_rest_6, f_rest_7, f_rest_8, f_rest_9, f_rest_10, f_rest_11, f_rest_12, f_rest_13, f_rest_14, f_rest_15, f_rest_16, f_rest_17, f_rest_18, f_rest_19, f_rest_20, f_rest_21, f_rest_22, f_rest_23, f_rest_24, f_rest_25, f_rest_26, f_rest_27, f_rest_28, f_rest_29, f_rest_30, f_rest_31, f_rest_32, f_rest_33, f_rest_34, f_rest_35, f_rest_36, f_rest_37, f_rest_38, f_rest_39, f_rest_40, f_rest_41, f_rest_42, f_rest_43, f_rest_44, opacity, scale_0, scale_1, scale_2, rot_0, rot_1, rot_2, rot_3
```, caption: [Az eredeti beolvasó függvény által támogatott `.ply` tulajdonságok listája]
) <ply_formatum_eredeti_txt>

A @ply_formatum_splatbol_txt. blokkban látható az a fejléc, amit parszolni szeretnénk, és a @ply_formatum_eredeti_txt. blokkban pedig azok a property-k listája, amit az eredeti beolvasó be tudott olvasni. A tulajdonságokon kívül a header többi része megegyezik.

A hiányzó értékek a gömbi harmonikusok, illetve a normálvektor (amit a beolvasó ezesetben nem használ fel), így semmi probléma nem adódik abból, hogyha 0-ra inicializáljuk az ismeretlen tulajdonságokat. A többi adatot pedig át kell rendezni, hogy a megfelelő sorrendben történjen a beolvasásuk. Ezeket a @parsefuggveny-gds. kódrészleten látható parse függvény el tudja végezni. A kód több revízión átment, és most már a ply importer része, de a logikája változatlan maradt.

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
```, caption: [A parse függvény robusztusabb lett]
) <parsefuggveny-gds>

=== GLTF adatfájl adatainak beolvasása
<gltf-beolvasas-fejezet>

Egy másik fájlformátum, aminek a beolvasása szükséges, a GLTF, ami a @gltf-bemutatas-fejezet. fejezetben került bemutatásra. Az implementálandó formátum részletes dokumentációja @GLTFExtSpec alatt érhető el. 

A részletes dokumentációnak köszönhetően az implementáció viszonylag zökkenőmentesen ment. Két dolgot szükséges megjegyezni, az egyik bizonyos paraméterek konverziójának szükségessége: a skálázás és az átlátszóság más skálán vannak tárolva a `.ply` formátumhoz képest, emiatt valamelyik formátum betöltésénél szükséges a konverziót elvégezni, hogy a tárolt reprezentáció már egységes legyen (skálázás: exponenciális, átlátszóság: szigmoid). A másik, hasonló probléma a gömbi harmonikusok sorrendje: a `.ply` formátumban csatornánként vannak kódolva: 15 piros, 15 zöld majd 15 kék szín, míg a `.gltf`-ben harmonikusonként, a 3 csatorna együtt: `RGBRGBRGB...` . Ezt is a beolvasás során szükséges az egyik importerben megoldani, illetve a belső reprezentációnál egyértelműen meghatározni, hogy mit milyen sorrendben, és skálán vár el. Ez az @gltf-pr-fejezet. fejezetben szintén érdekes lesz, mert az ottani kódbázisban más a belső reprezentáció, mint nálam.

A formátum implementálása mellett a másik nehézséget a tesztfájlok beszerzése okozta: mindenképpen szerettem volna hivatalos fájlokat szerezni, de a Khronos oldalán, és repository-jaiban sehol sem találtam GS modelleket, amik garantáltan megfelelő GLTF formátumúak. Így muszáj voltam a @splattransform-fejezet. fejezetben bemutatott programot használni. A konvertált fájlokat jól be tudta tölteni az importer. Fontos megjegyezni, hogy a Godot-nak már eleve van GLTF importere, ami a sima modellek betöltésére képes, és a pontfelhős modelleket pontokként tudja megjeleníteni, a formátum backwards compatibility-je miatt. Ahhoz, hogy a mi importerünkkel tudjuk a modellt betölteni, egyszerűen át lehet váltani a modell betöltéséhez használt importert a motor felületén.

A betöltés és megjelenítés eredménye látható a @relightable_and_sh_together. ábrán, ahol a bonsai fa GLB formátumú fájlból származik. Az ábrán már a gömbi harmonikusok is helyesen működnek, miután a megjelenítőnél az @gombi-harmonikus-trafo-fejezet. fejezetbeli javítást elvégeztem, és látható a modellen a @sh_transformation_difference. ábrán kiemelt megcsillanás is.

Megjegyzendő, hogy a @gltf-bemutatas-fejezet. fejezetben említett tömörített változat implementálása is felmerült bennem, viszont mivel a kitömörítés natív kód és könyvtárak nélkül, tisztán GDScript-ben problémásnak tűnik, illetve a szabvány még nem is végleges, az ötletet elvetettem.

== Kollaboráció a másik implementációval
<kollab-onallomunka-fejezet>

A @kinai-repo-fejezet. fejezetben leírt implementáció a projekt végrehajtása során bukkant fel, és mivel ugyanazon a kódbázison alapult mindkét plugin, a @valasztott-modszer-fejezet. fejezetben leírtaknak megfelelően úgy döntöttem, hogy kollaborációt kezdeményezek @kollaboracio-kezdemenyezese.

Ebben bemutattam a projektem röviden, leírtam, hogy milyen javításokat tudna tőlem átvenni, illetve leírtam további terveimet. Nem írtam le, de fejben megjegyeztem, hogy miben jobb az ő implementációja. Először távolságtartó választ adott, de a későbbiekben teljesen együttműködően viselkedett, több PR-t is merge-elt, amiket lentebb taglalok.

Még mielőtt explicit pull request-et nyitottam volna neki, egy pár, a kollaborációs issue-ban említett, illetve nem említett fejlesztést gyorsan be is épített: növelte a támogatott fájlformátumok számát #footnote[https://github.com/ReconWorldLab/godot-gaussian-splatting/commit/25040d49c41adc7fca54f6eed8321a0e28811b8c], kijavította ő is a @amd-bug-fejezet. fejezetben említett AMD bugot #footnote[https://github.com/ReconWorldLab/godot-gaussian-splatting/commit/d0c5d380eccf4756defdee0b7bc24554eaf4a530], illetve, habár nem említettem meg, mert nekem nem tűnt fel, de megjavította az @kiterjedes-iranyai-trafo-fejezet. fejezetben leírthoz hasonló problémáját a kovariancia mátrix transzformációjának #footnote[https://github.com/ReconWorldLab/godot-gaussian-splatting/commit/a811baab6b0ff3d33d6ee24e5e14d30e9912f41b]. Ez utóbbi lehet, hogy teljesen független javítás, de feltételezhetően a képek, vagy kódok összehasonlítása mutatta őt a probléma forrása felé.

Az ő kódbázisa pedig jóval robusztusabb volt: nálam csak előre meghatározott, fix mennyiségű modellt lehet betölteni, még szerepelt a @godot-relighting-fejezet. fejezetben kijavított probléma, amitől az editor eléggé akadozott, és néha kifagyott, illetve összességében a kompozitoreffektes megoldás megbízhatóbbnak tűnt. Emellett a blending, átlátszóság jobban működött nála. Ezek miatt mindenképpen szerettem volna én is kísérletezni az ő kódjával, ezt meg is tettem az @compositoreffect-onallomunka-fejezet. fejezetben.

=== Ikonok, dinamikus láthatóság és instancing Pull Request
<ikon-dinlat-instancing-pr-fejezet>

A kísérletezés folytatásaként ide is portoltam a @editor-ikonok-fejezet. fejezetben leírt editor ikonokat, illetve az @igazi_dinamikus_lathatosag-fejezet\-beli hatékony dinamikus láthatóságot, és az @instancing-fejezet\-beli instancing-et pedig itt implementáltam. Ezekről nyitottam neki issue-kat, ahol egy-egy részletet (például a `.svg.import` fájlok fehérlistázását #footnote[https://github.com/ReconWorldLab/godot-gaussian-splatting/issues/4]) megbeszéltük, majd a három módosítással egy pull request-et is #footnote[https://github.com/ReconWorldLab/godot-gaussian-splatting/pull/6]. Ezt ő tesztelte, merge-elte és megköszönte, majd hozzá is adott az acknowledgements-hez #footnote[https://github.com/ReconWorldLab/godot-gaussian-splatting#0x0a-acknowledgements].

=== GLTF import Pull Request
<gltf-pr-fejezet>

Miután az @gltf-beolvasas-fejezet. fejezetben a GLTF importálást először a saját kódbázisomban implementáltam, úgy gondoltam, hogy ez is egy olyan, jól elhatárolható feature, amiről érdemes lehet pull request-et nyitni. Így áttettem az importert az ő kódbázisára és az ő belső reprezentációjára, nyitottam egy PR-t, amit ő nem sokkal később merge-elt is szintén #footnote[https://github.com/ReconWorldLab/godot-gaussian-splatting/pull/28]. 

=== Issue a gömbi harmonikusok helyes transzformációjáról

A tesztelés során tűnt fel, hogy a gömbi harmonikusok nála sincsenek helyesen transzformálva, így nyitottam egy issue-t róla #footnote[https://github.com/ReconWorldLab/godot-gaussian-splatting/issues/29], leírva az @gombi-harmonikus-trafo-fejezet. fejezetben bemutatott javítást is röviden. Erről nem nyitottam pull request-et, mert a javítás nagyon apró: 1-3 sor módosításából állt összesen. A problémát nem sokkal később ki is javította #footnote[https://github.com/ReconWorldLab/godot-gaussian-splatting/commit/9ef048835533fd5c3d14b32e77de34bada9f8f68] a javasolt logikával, azzal a többlettel, hogy mindkét backendjénél ki kellett javítani, amire én nem gondoltam volna.

== Kitérő: Typst

Még egy, a diplomaterv írása során extenzíven használt eszközt mindenképpen szeretnék megemlíteni, habár nem tartozik a Gaussian Splatting témaköréhez: ez pedig a Typst nevű typesetting nyelv és compiler #footnote[https://typst.app/]. Ezen dokumentum elkészítéséhez a Typst-et használom.

A Typst egy modern LaText alternatíva, ami mind a markdown-nal, mind a WYSIWYG #footnote[https://en.wikipedia.org/wiki/WYSIWYG] szerkesztőkkel (LibreOffice Writer, Microsoft Word), mind a LaTeX-szel szemben rendelkezik előnyökkel. Egy berlini cég készíti, és szabad, nyílt forráskódú a fordítója. Az első verzióját nem régen, 2023-ban adták ki, mégis gyors elterjedésnek indult.

Nekem a kollégiumi szobatársam mutatta be, aki elkészítette a nyelvhez a diplomaterv sablont is: ez a @typst-bme-dipterv-sablon alatt érhető el. Időközben én is finomhangoltam a sablont, de meglepően fájdalommentes volt bármi, amit el akartam érni benne, annak ellenére, hogy a nyelvet korábban nem ismertem.

Az alapképzésen a szakdolgozatomat LibreOffice Writer-ben írtam, mivel LaTeX-et nem szerettem volna használni, és bármilyen egyéb online WYSIWYG szerkesztő nem volt elég okos az irodalomjegyzék normális kezeléséhez. Hozzá kell tennem, hogy a Writer-ben is kifejezetten szörnyű volt mind az irodalomjegyzék-, mind az ábra- és a fejezetreferenciák kezelése, így az elvárás léce nem volt magason.

Hasonlóan sokat javított a kódblokkok beszúrásán is a Typst, ugyanis kifejezetten könnyen lehet őket számozni, referálni rájuk, és a szintaktika alapú színezést is teljesen jól támogatja, a markdown-hoz hasonlóan. Az egyéb formázás pedig általánosságban véve sokkal könnyebben kezelhető úgy, hogy nincsenek láthatatlan formázási szabályok, vagy véletlenül máshonnan bemásolt formázás.

A LaTeX-szel nincs nagyon sok tapasztalatom, de az alatt az idő alatt, amíg foglalkoztam vele, az a benyomásom volt róla, hogy elég körülményes a használata. Unicode támogatása elég esetleges (például a ▀ dobozrajzoló karakter hibát okozott, ezt annak idején kifejezetten sokáig próbáltam debugolni), a dokumentumhoz általában legalább 3, furcsa szintaktikájú fájlra van szükség, és a fordítás során az egész mappa tele lesz ideiglenes fájlokkal szemetelve. A szintaktikája véleményem szerint csúnya, és nehézkes. Ezen kívül sokféle implementáció és könyvtár van, ami egy elég fragmentált ökoszisztémához vezethet. Lehetne Overleaf-et #footnote[https://www.overleaf.com/] használni, de a hosszú fordítási idő és a szintaktika ott is hátrány.

Ezzel szemben a Typst instant fordul, ugyanúgy rendelkezik egy egyszerű online szerkesztővel, de a parancssori fordító használata is egyértelmű, egyszerű, és egyféle nyilvánvaló implementáció és módszer van rá. A szobatársam sablonja lényegében egy darab sablon fájlból áll, és a fordítás során sem lesz teleszemetelve a mappa. A szintaktika egyszerű és könnyen használható, és összességében mindig találtam egyszerű megoldást a problémákra, amiket meg akartam vele oldani.

Úgyhogy összességében, habár az elvárásaim nem voltak magason, kifejezetten használhatónak találtam a Typst-et, és amennyiben következő alkalommal egy hasonló dokumentumot kell írjak, nagy valószínűséggel újra ezt választom. Mindenkinek, akinek alapvetően tetszik a LaTeX filozófiája, de egy fájdalommentesebb megoldásra vágyik, jó szívvel tudom ajánlani.


= Plugin alkalmazásai, eredmények
<plugin-alkalmazasai-fejezet>

== Használati utasítás

A plugin integrálása egy már meglevő Godot projektbe az @plugin-keszitese-fejezet. fejezetben leírtaknak megfelelően elég egyszerű: a mappát be kell másolni az `addons` mappába, a projektbeállításoknál be kell kapcsolni a plugint, majd egy esetleges újraindítás után már be is lehet tenni a `SplatCloud3D` node-ot a jelenetbe.

A pontfelhős modelleket a projektbe helyezés után a motor automatikusan importálja, de esetleg ki kell választani a helyes importert az Import fülön. Sikeres importálás esetén a modellt lehet drag-n-droppolni az inspectorba, ha a `SplatCloud3D` node van a jelenetfában kijelölve, sikertelen importálás esetén pedig a konzolban látható a hibaüzenet.

== Autószimulátor, mint példafelhasználás
<vitavehicle-peldafelhasznalas-fejezet>

#figure(
  image("pictures/vitavehicle_car.png")
  , caption: [Példa képernyőkép a VitaVehicle autószimulátorról]
) <vitavehicle_car>

Az első teszt-alkalmazás egy másik projekt felhasználásával a @vitavehicle-gh alatt elérhető, VitaVehicle nevű, viszonylag realisztikus autószimulátor projekten alapul. Az eredeti projektet jreo03 készítette, és elég fapados modelleket és kód-esztétikát használó, de teljesen működőképes projektről van szó. Maga az autó fizikája tényleg kifejezetten kifinomultnak érződik. A projekt szintén a MIT licensz alatt érhető el. Egy példakép a @vitavehicle_car. ábrán látható.

Az @plugin-keszitese-fejezet. fejezetbeli munka ekkoriban még nem készült el, így a két Godot projektet össze kellett fésülni. Az összefésülés első lépéseként a fájlokat össze kellett másolni. A fő konfliktust a projektfájl, a `project.godot` okozta, ez a projektbeállításokat tartalmazza. Szerencsére egy szöveges fájlformátum, így össze lehet a két fájlt hasonlítani, és akár szövegszerkesztővel összemásolni a tartalmat, akár a látott különbségek alapján a Godot-n belül újra alkalmazni a szükséges beállításokat. A lényegi módosítások a billentyűzet bemenet és az autoload-ok listája volt, egy-két egyéb beállítás mellett.

A másik megoldandó probléma az alapértelmezett jelenet volt, mivel mindkét projekt arra számított, hogy a saját jelenetével fut a játék. A legegyszerűbb megoldás, ha az egyik jelenet gyökerének a gyerekeként szúrjuk be a teljes másik jelenetet, és az igazi gyökér például az @automata-objektum-megtalalas-fejezet. fejezet logikája miatt szükségszerűen a pontfelhős projektből kellett származzon. Szerencsére a másik projekt főjelenetével nem volt különösebb gond abból, hogy nem ő lett az igazi gyökér.

#figure(
  image("pictures/vitavehicle_project_combination.png")
  , caption: [A VitaVehicle projekt összekombinálása a GS megjelenítővel]
) <vitavehicle_project_combination>

A @vitavehicle_project_combination. ábrán már a két projekt összekombinálásának eredménye látható: hozzáadtam az alapvetően fehér, textúra nélküli, háromszöghálós autóhoz egy GS modellt, egy kis platós teherautót. Egyelőre mindkét modellt láthatóan tartom, hogy lehessen látni a különbségeket, esetleges eltéréseket. A platós teherautó szépen követte is a fehér autót (láthatóan megegyezett a transzformjuk), egyfajta csúnya stutteringtől eltekintve. Ennek a megjavítását a @vitavehicle-stuttering-fejezet. fejezetben részletezem.

#figure(
  image("pictures/vitavehicle_end_result.png")
  , caption: [A kombinálás végső eredménye]
) <vitavehicle_end_result>

A @vitavehicle_end_result. ábrán látható a tesztprojekt végleges eredménye. A platós teherautó modelljét lecseréltem egy Toyota modellre, amit már a korábbi, például a @lathatosag_lathato\-@lathatosag_nemlathato. ábrákról is ismerünk, ez is egy GS modell. Ebből kettő is van a jelenetben, egymástól függetlenül irányíthatóak, és a fizikai interakciók közöttük, mind a pálya, illetve a háttérben látható plüssmaci (szintén GS modell) között a várhatónak megfelelően történik. Az autók és a maci fent maradnak a pályán, és ha egymásnak mennek, enyhén eltolják egymást.

Mivel a motorban eleve a fizika a megjelenítéstől viszonylag függetlenül történik, így a kerék nélküli Toyota GS modellt, illetve a Toyota kerekének GS modellét a megfelelő méretre skálázva, és a node-ját a megfelelő szülő gyerekeként betéve egyszerűen le lehetett cserélni az eddigi `MeshInstance3D` node-ok által megjelenített háromszöghálós autótestet és kerekeket. A kerekek ezek után ugyanúgy képesek voltak forogni, mint eddig, illetve az első kerekek még a kormányzásra is ugyanúgy tudtak reagálni (elfordulni), mint eddig.

Meg érdemes jegyezni, hogy a pálya, és a háttér maradt az eredeti, háromszöghálós modell, így az @melyseghelyes-osszekombinalas-fejezet\-beli mélységhelyes összekombinálás is fontos szerepet játszott a példafelhasználásban.

=== Stuttering bug
<vitavehicle-stuttering-fejezet>

Az összekombinálást, és sikeres megjelenítést követően arra lettem figyelmes, hogy mozgó autó esetén a két autó-modell egy-egy képkockányit ugrál egymáshoz képest előre-hátra. Pontosabban a GS modell némelyik képkockában jó helyen van, némelyikben pedig egy képkockával hátrébb, mint kellene.

Ezt az okozta, hogy az autós projektben a kamerát egy script állította, míg a pacás projektben ugyanezen (aktív) kamera transzformját egy másik script továbbította a GPU-nak. Ez a két script pedig nem meghatározott sorrendben futott, így néha az egyik futott előbb, néha a másik.

A megoldást az jelentette, hogy a kamera feltöltő script-nek a process priority-jét #footnote[https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-property-process-priority] magasabbra kellett állítani, és ezáltal a sorrend már determinisztikus lett, mindig a transzformáció feltöltése futott később.

== When Hamsters Attack TD, mint példafelhasználás

A When Hamsters Attack TD egy When Penguins Attack TD #footnote[https://armorgames.com/play/4600/when-penguins-attack-td] által ihletett, 3D grafikával rendelkező toronyvédő játék, amit a Játékfejlesztés labor című tárgy nagy házi feladataként készítettem Godot-ban @when-hamsters-attack-td. Egy példa képernyőkép az eredeti játékról a @what_original_screenshot. ábrán látható. Második példafelhasználásként ennek a játéknak az ellenfeleit cserélem le pontfelhős modellekre.

Mivel ez a példafelhasználás a projekt végén történt, így a fentebb leírt feature-ök jó része rendelkezésre állt. A változatok közül az @egyuttes-megjelenites-fejezet\-beli munka eredményeként előállt branch-et használtam.

Az integráció szempontjából legfontosabb, hogy a plugin különválasztása megtörtént, így jóval egyszerűbben el lehet addig jutni, hogy a pályán a játszható játék mellett egy GS modellt is meg lehet jeleníteni. Ehhez lényegében a mappa projektbe másolása, a plugin bekapcsolása és egy újraindításon kívül mást nem is kell csinálni. A `SplatCloud3D` node-ot be lehet tenni bármelyik jelenetbe, és az editorban, illetve futtatáskor is látszik a modell, ha helyesen lett importálva.

#figure(
  image("pictures/what_original_screenshot.png")
  , caption: [Példa képernyőkép a When Hamsters Attack TD játékról]
) <what_original_screenshot>

A további integrációs feladatok egy része a modellek lecserélése: a 3-féle ellenfél modelljét a plüssmacira, a Toyotára és a bonsai fára cserélem le. A bonsai fa alatt otthagyom az eredeti modell lánctalpát, így a két modell együtt adja az ellenfelet. Külön figyelmet igényelt az irány, mivel az új modellek nem feltétlen ugyanabba az irányba néztek, mint az eredetiek, illetve a scriptekben is figyelni kellett, hogy a megfelelő referenciákat lecseréljem az új modellekre. Semmi nem használta a `MeshInstance3D`-séget, de használva volt például a transzform, animációhoz.

#figure(
  image("pictures/teddy_anim_vid.png")
  , caption: [Az infantery animációja működik a teddy modellen]
) <teddy_anim_vid>

A @teddy_anim_vid. ábrán látható az egyik egység halálának animációja, ami előrebukásból, kis csúszásból, majd föld alá süllyedésből áll. Az irányok és az animálandó node beállítása után minden probléma nélkül működött a GS modellen is, mint ahogyan a háromszöghálós modellen korábban, a bobbing séta animációval együtt. A képek balról jobbra, majd fentről le nézendők.

Mivel a GS modellek dinamikus hozzáadása és törlése nem támogatott, így object pooling-ot implementáltam. Előre leidéztem a szükséges mennyiségű modellt, majd az új ellenfél idézésekor `RemoteTransform3D`-t #footnote[https://docs.godotengine.org/en/stable/classes/class_remotetransform3d.html] használva a megfelelő node-hoz kötöttem a látható modellt. Halálkor pedig visszaadtam a modellt a pool-nak. Ez picit nehézkesebbé, és nem drop-in replacement-té tette ezt a megoldást, mivel az eddigi jelenetöröklési hierarchia, és gyerekként felülírt modell helyett muszáj volt a szülőnek is tudni a lehetséges ellenféltípusokról, hogy a megfelelő modellt tudja a pool-tól kérni. Cserébe viszont megoldotta a módszer a dinamikus ellenfél-idézést, és megsemmisítést.

A konverzió végső eredménye a @what_end_result. ábrán látható, és ezután az elvárásoknak megfelelően a játék ugyanúgy játszható, mint eddig.

#figure(
  image("pictures/what_end_result.png")
  , caption: [A lecserélt modellekkel ugyanúgy játszható a játék]
) <what_end_result>

A licensz még említésre méltó, ugyanis a játék projekt GPL-3.0 licenszű, így a módosított projekt is szükségszerűen ugyanezen licensz alatt lesz elérhető. Ez nem ütközik a plugin MIT licenszébe, azt probléma nélkül közzé lehet tenni más licensz alatt.

== Asset Library plugin kontribúciók

A plugin könnyen letölthető, és betehető Godot projektekbe a @dipterv-github-repo GitHub repository különböző ágaiból letöltve. Egy másik lehetőség a terjesztésre a Godot Asset Library #footnote[https://godotengine.org/asset-library/asset], ahova fel lehet pluginokat is tölteni, és ezek az editoron belülről is betehetők a motorba. Én fontolgattam a feltöltést, viszont végül a projekt fragmentáltsága, szerteágazósága miatt (különböző ágakon különböző architektúrájú megoldásokat teszteltem), illetve a közben megjelent @kinai-repo-fejezet. fejezetben bemutatott projekt miatt úgy gondoltam, hogy nem adna annyit az ökoszisztémához egy másik asset library bejegyzés.

A munkám egy része viszont a @kollab-onallomunka-fejezet. fejezetnek köszönhetően így is fent van az asset library-ben: a diplomaterv írásakor a GLTF importer kivételével a többi kontribúció már benne van a letölthető verziójában a GDGS #footnote[https://godotengine.org/asset-library/asset/5076] pluginnak.

== Újravilágítási módszerek összehasonlítása

Egy jó összehasonlítási szempontot ad az újravilágítás, mind az én implementációim között, mind más implementációval. A @kinai-repo-fejezet. fejezetben bemutatott projekt is implementált újravilágíthatóságot, de teljesen más technikával.

=== Összehasonlított módszerek

Az általam implementált újravilágíthatóság-technikák a @relightolas-sajatmunka-fejezet. fejezetben kerülnek bemutatásra, de összefoglalva arról van szó, hogy pacánként eltárolunk extra anyaginformációkat, és egyszerű fizikai alapú renderelést alkalmazunk a pacákra az anyagtulajdonságok és a jelenetbeli fények figyelembe vételével.

Ezzel szemben a @kinai-repo-fejezet\-beli implementáció (ReconWorldLab implementációja, GDGS) azt a technológiát használja bármilyen GS modell újravilágítására, amit collision generálására is használ. Az ő implementációjának van egy olyan köztes feature-je, hogy tud a pacákból egy voxel field-et generálni. Ez a mező sok mindenhez hasznos: GS modell tud árnyékot vetni (látható a @suzanne_gdgs_relit. ábrán, GS modellre viszont nem vetül árnyék), és lehet fizikai kiterjedést (collision) generálni automatán. Ez segítség a felhasználónak, ugyanis nélküle magától kell kiválasztania a megfelelő alakzatot, ami legjobban illik a modellre. Megjegyzendő, hogy ez azért háromszögháló alapú reprezentációknál is gyakori: sokszor a 3D karakter collision-je egy egyszerű kapszula, a komplex vizuális modell ellenére. Ezen kívül ennek a voxel field-nek a segítségével egy lighting proxy-t is lehet számolni, ami alapján a rendszer újra tud világítani bármilyen GS modellt @gdgs-relighting-doc.

=== Újravilágítás paraméterei

Vegyük észre, hogy most már 3 különböző fajta világítási, fénnyel kapcsolatos módszerről van szó, és egyik sem zárja ki a másikat. Alapesetben minden pacának van színe. Ezen felül némelyeknek vannak gömbi harmonikusai (SH), ami nézetirány-függő fényeket tesz lehetővé. Ez erős megcsillanás esetén nem feltétlenül jó, ha újra szeretnénk a modellt világítani, de ezesetben könnyen el is lehet ezt az információt dobni, és csak a DC komponenst használni, mint szín.

Másrészt minden pacának lehetnek anyagtulajdonságai (például roughness, metallic), illetve normálvektora, aminek segítségével el tudjuk végezni az újravilágítást pacánként. Ez a gyakorlatban nekünk a Mesh2Splat (@mesh2splat-program-fejezet. fejezet) kimenetét jelenti.

Harmadrészt pedig, amennyiben egy gömbi harmonikusos, vagy anélküli modellünk van, és mégis figyelembe szeretnénk venni a jelenetbeli fényeket, akkor valamilyen módon ki kell találni az előbb említett paraméterekre értelmes értékeket. Ez az anyagtulajdonságok esetén nem nehéz, a probléma a normálvektorral van. A @kinai-repo-fejezet\-beli implementációban értelmezésem szerint erre szükséges a voxel mező, az ambient occlusion és konfidenciája mellett. Az én @relightolas-sajatszamitas-fejezet\-beli implementációm is implementált egy sokkal egyszerűbb, normálvektor-kitaláló módszert: minden egyes gausszi eloszlású blob legkisebb kiterjedésének irányát vette a normálvektornak. Ez elméletileg logikus, mivel egy felület esetén a paca a felületre merőleges irányba kellene, hogy a legkisebb kiterjedéssel rendelkezzen. Viszont a gyakorlatban nem adott használható eredményt, amint a @teddy_bonsai_rossznormal_relit. ábra is mutatja.

=== Összehasonlítás

Ezt a sokféle változó paramétert, és többféle implementációs lehetőséget próbáltam egyszerűen, de a lehető legjobban lefedni a @tablazat_ujravilagitas. táblázatban: itt 3 modellt teszteltem le 3-féle implementációval. A tesztelt modellek már fentebbről ismerősek lehetnek: Teddy pacáinak csak a legszükségesebb tulajdonságai vannak meg, Bonsai ezen kívül rendelkezik még gömbi harmonikusokkal, míg Suzanne pedig a Mesh2Splat újravilágítási paramétereivel rendelkezik a legszükségesebb tulajdonságok mellett.

A tesztelt implementációk közül is 3 van. Első az @relightolas-sajatszamitas-fejezet. fejezetbeli kompozitoreffektes megoldás, ami a pacák kiterjedéséből megpróbálja a normálvektort minden áron kitalálni, és újravilágítani a modellt. Ez eldobja a gömbi harmonikusok információit, ha vannak. Második a @godot-relighting-fejezet. fejezetbeli fullscreen quad-os megoldás, ami megtartja, és használja a gömbi harmonikusokat, ha vannak, illetve felhasználja az újravilágítás paramétereit is, ha vannak. Harmadik pedig ReconWorldLab implementációja, ami a @kinai-repo-fejezet. fejezetben került bemutatásra (rövid nevén GDGS: GoDot Gaussian Splatting), ez alapértelmezetten felhasználja a gömbi harmonikusokat, ha vannak, és bake-elhető light proxy segítségével minden modellből ki tud normálvektorokat találni.

#figure(table(columns:4,
  [*Modell neve*], [*Teddy*], [*Bonsai*], [*Suzanne*], 
  [*Gömbi harmonikusok*], [Nincsenek], [Vannak], [Nincsenek], 
  [*Anyagtulajdonságok és normál*], [Nincsenek], [Nincsenek], [Vannak], 
  [*Saját fényszámítással (@relightolas-sajatszamitas-fejezet)*], [@teddy_bonsai_rossznormal_relit. ábra], [@teddy_bonsai_rossznormal_relit. ábra], [@relightolhato_mindketshaded. ábra],
  [*Godot fényszámításával (@godot-relighting-fejezet)*], [Érintetlen], [@relightable_and_sh_together. ábra], [@relightolhato_mindketshaded\-@relightable_and_sh_together. ábra],
  [*GDGS (@kinai-repo-fejezet)*], [@teddy_gdgs_relit. ábra], [@bonsai_gdgs_relit. ábra], [@suzanne_gdgs_relit. ábra]
), caption: [Ábrák számai a modellek és implementációk függvényében]
) <tablazat_ujravilagitas>

#figure(
  image("pictures/teddy_bonsai_rossznormal_relit.png")
  , caption: [Teddy és Bonsai újravilágítási kísérlet megtippelt normálokkal]
) <teddy_bonsai_rossznormal_relit>

A @teddy_bonsai_rossznormal_relit. ábrán láthatóan a normálvektort nem lehet megtippelni a paca legkisebb kiterjedésének irányából, megfigyelendő, hogy még a simának tekinthető talapzata Teddy-nek is kifejezetten rosszul lett megvilágítva. A helyes, kivilágítatlan modell például a @teddy_gdgs_relit. ábrán látható. A saját implementációk által megjelenített Suzanne értékelése és összehasonlítása a @relightolas-sajatmunka-fejezet. fejezetben szerepel. A @teddy_bonsai_rossznormal_relit. ábrából tanulva az @godot-relighting-fejezet\-beli implementációban inkább úgy általánosítottam az újravilágítási paramétereket, hogy nem meglétük esetén nem történik fényszámítás, így Teddy és Bonsai ezen implementáció alatt érintetlenek, ugyanúgy jelennek meg, mint újravilágítás nélkül.

#figure(
  image("pictures/teddy_gdgs_relit.png")
  , caption: [Teddy: bal oldalt az eredeti modell, jobb oldalt GDGS által újravilágítva]
) <teddy_gdgs_relit>

#figure(
  image("pictures/bonsai_gdgs_relit.png")
  , caption: [Bonsai: bal oldalt az eredeti modell, jobb oldalt GDGS által újravilágítva]
) <bonsai_gdgs_relit>

A GDGS mivel teljesen más módszert használ, így az eredményei is teljesen mások lesznek, ettől érdekes az összehasonlítás. A @teddy_gdgs_relit\-@bonsai_gdgs_relit. ábrán láthatóak a Teddy és Bonsai modellek újravilágítás nélkül, illetve újravilágítással. Habár azért például a Teddy-nél lehet látni a használt voxeleket, az eredmény mégis impresszív. Ahhoz képest, hogy a modelleknek nem volt semmi újravilágítási információja, a program képes volt teljesen értelmes megvilágítást alkalmazni. A látható voxelhatárok ellen pedig lehetséges a felbontás minőségét állítani. A bonsai esetén az újravilágításon felül még a gömbi harmonikusok is alkalmazva vannak, látható a fatörzs megcsillanása, viszont ez kérésre kikapcsolható. Ami kevésbé impresszív viszont, az a Suzanne újravilágítása: a @suzanne_gdgs_relit. ábrán láthatóan a Mesh2Splat kimenete nem kompatibilis a GDGS újravilágításával. Ezt az újravilágítási paraméterek állítása, például voxelméret sem oldotta meg. Kikapcsolt újravilágítás esetén pedig a modell teljesen egyszínű, így csak a körvonala látszik, a részletek, alak nem.

#figure(
  image("pictures/suzanne_gdgs_relit.png")
  , caption: [Suzanne, GDGS általi újravilágítás próbálkozással]
) <suzanne_gdgs_relit>

Egy apró megjegyzés, amit ReconWorldLab is megjegyzett @gdgs-relighting-doc, hogy amennyiben egy valós, felvett, paraméteroptimalizált jelenetet világítunk újra, akkor az tulajdonképpen kétszer lesz megvilágítva. Ugyanis az eredeti felvételkor is voltak már a valódi jelenetben fényforrások, amik esetleg megcsillanásokat, árnyékokat, sötétebb, világosabb részeket eredményeztek, és ezt mi nem tudjuk kiszedni a jelenetből. A gömbi harmonikusok kikapcsolása megcsillanások esetén segíthet, de legfeljebb egy nagyon apró részét oldja meg a kérdésnek. Esetleg létezhet olyan program, ami az újravilágítási paramétereket megpróbálja kitalálni például a gömbi harmonikusokból, esetleg különböző megvilágítással körbefotózott modellből, de ez egy nagyon nehéz feladatnak tűnik.

Összességében azt szükséges mondani, hogy nincs egyféle jó megoldás az újravilágításra, a megfelelő megoldás mind a használt modelltől, mind a felhasználás körülményeitől függ. Így egy ideális pluginnak szükséges az összes lehetséges módszert a felhasználó számára elérhetővé tenni, hogy a beállítások segítségével a saját alkalmazási környezetére tudja szabni a megjelenítést. Ezt a GDGS elég jól csinálja, csak a modellel érkező újravilágítási paramétereket nem tudja felhasználni.



= Összefoglaló

A diplomaterv írása során sokat tanultam mind a technológiáról, mind egyéb, hasznos készségek terén. Kezdetnek megismerkedtünk a 3D Gaussian Splatting technológiával, majd a Godot játékmotorba való integráció során különböző programozási, architekturális problémákat oldottunk meg. Az implementáció közben figyelemmel kísértük a konkurens megoldásokat, és kollaborációt hajtottunk végre, ahol értelme volt. Végül alkalmazási példákon keresztül mutattuk be a készített plugin használatát, használhatóságát, és részletesen összehasonlítottuk az újravilágítást végző implementációkat. Ezen dokumentum írása során pedig megismerkedtünk egy feltörekvő markup filozófiájú nyelvvel, a Typst-tel.

Jövőbeli fejlesztésként további életminőséget javító fejlesztéseket lehetne a pluginon végrehajtani, például a megjeleníthető GS modellek számának dinamikusan változatathatóvá tételét, a különböző ágakon levő tesztek, implementációk közötti váltást lehetővé tevő kapcsolók implementációját, vagy az editor viewportban GS modelleknek kattintással való kijelölhetőségét. Nagyobb szabású fejlesztési lehetőségek között szerepel a voxel field alapú, vagy hasonló logikájú feldolgozása a pontfelhőnek, collisionhöz és árnyékhoz, a @idobeliseg-fejezet. fejezetben szereplő időben változó pontfelhők vizsgálata, támogatása, illetve többféle, többek között tömörített fájlformátumok támogatása.

A mindenki számára szabadon letölthető plugin-változataim, illetve a másik implementációhoz történt kontribúcióim alapján viszont az elért eredménnyel elégedett vagyok, a projektet sikeresnek titulálom. Remélhetőleg hozzá tudtam tenni a Godot-ba integrált Gaussian Splatting könyvtárak minőségének általános fejlődéséhez.

#bibliography("bibliography.yml")

#import "prompts.typ": prompts

#show: appendix.with(
  used-ai: true,
  ai-usage: (
    (
      category: [Új ötletek, megoldási javaslatok és programkód generálása],
      tool: [ChatGPT, Gemini],
      parts: [@onallo-munka-bemutatasa\-@plugin-alkalmazasai-fejezet. fejezet],
      share: [25%],
      prompts: ([_Az ezen táblázatról szóló szabály meghozása előtt a projekthez használt promptok nem kerültek mentésre. Ezek viszonylag kis, specifikus kérések voltak, kis hatással._
    
    
        ], ..prompts,
      ),
    ),
    (
      category: [Egyéb: Absztrakt angol nyelvűre fordítása],
      tool: [Gemini],
      parts: [Abstract],
      share: [95%],
      prompts: [Nice. It's been a while. Now I wrote the thesis text. Below I paste the abstract in Hungarian, please translate it into English. Use simple english, but still it should be fine for a master thesis' abstract.

      _Absztrakt akkori változata_],
    ),
    (
      category: [Egyéb: AI nyilatkozat írása a Typst sablonhoz],
      tool: [Gemini],
      parts: [@ai-nyilatkozat-fejezet függelék],
      share: [50%],
      prompts: (
        [in typst I have this for list entries. I want the X to be in the middle of the square, but probably because of some spacing it is off. I want the exact size for the square, I don't want to make it bigger. How do I reduce the spacing or make it negative, so that the X goes up and right relative to the square, and they also take less space (only the space that the empty square would)?
```
#set list(marker: square(height: 0.75em)[✘])
```
The checkbox character doesn't work well, its using a different font and its ugly],
        [_AI_nyilatkozat_tablazat_HU.tex_
        
        Nice. To be fair the whole task is to translate the attached latex template to typst. So far I've got until here:
        
_AI nyilatkozat kódjának akkori változata_

Please try to finish the rest. Take special care to nice spacing and the lines between rows, if you can.],
[Yeah I like the non-rowgutter version. 
The box looks worse than it did, but I do like the non-code-duplicatedness. Please however make it like this:

```
#let checkbox(texttt) = square(height: 0.75em, inset: 0pt)[
  #place(center + horizon, text(top-edge: "bounds", bottom-edge: "bounds")[texttt])
]``` (though this doesnt work cuz it writes texttt instead of the variable xddd)

Also, sometimes we need to put multiple prompts, so please make usage-row accept multiple values for the prompt, and add multiple lines after the usage with "prompt lényegi része" on the left 1, and the prompt on the right 3 cells

And please put the whole thing into the appendix function, so far it looks like this:


```
#let appendix(body) = {
  heading(level: 1, numbering: none)[Függelék]
  set heading(offset: 1, numbering: (..numbers) => {
    let nums = numbers.pos()
    let _ = nums.remove(0)
    numbering("A.1.", ..nums)
  })
  counter(heading).update(0)
  body
}
```

and it is used like this:

```
#show: appendix

= Nyilatkozat generatív mesterséges intelligencia alkalmazásáról
...
```

But I'd want to be able to wrap this text and table into the appendix, while still being able to add other appendix entries after the table. And also be able to populate the ai table from the usage, while the table itself stays in the template.],
[nice, this is pretty good! I want to ask for a few small adjustments:
10pt for text size is good (?)
no need for the 0.5em vspace just before the table
I want to be able to reorganize the usage-categories, but it is fine if the templates text is in the user-file, since then they can customize the text if they want more easily. Also, we should be able to have multiple "egyéb" options. Or all of them can be done with the same logic, and then it becomes simpler as well.
I want to draw no table at all if they say they didn't use any AI. (then any info that is passed for the table can be dropped, but it should still compile if possible)],
[nice, thats good. Now, please write me a python script that converts the attached prompts into the required format. Please pay special attention to line breaks, code blocks, characters that need escaping, etc. It would be good to convert the prompts to a separate file, and have an easy way to "include" that file in the main.typ, since this will be a huge amount of text.

They all go to one category, titled "Új ötletek, megoldási javaslatok és programkód generálása", I will take care of that.

So please write a script that scrapes all of my prompts in the attached file, and word-by-word copies them to this new file. If there is an attachment file to the prompt as well, put the name of the file in front of the prompt like this:
`_file.ext akkori változata_` (\_ so that it is in italics)
No need to scrape the responses you gave.
If there is code pasted into the prompt too, you don't need to auto-recognize that and put the whole thing into a codeblock, but please make sure to escape the characters in a way that I don't get comp.error when I try to see the result. ],

[
  _extract_prompts.py akkori változata_
  
  okay, that is starting to take shape. Now I have the typst file like this:
```
[

_rendered\_image\.gd akkori változata_ \
Hi\. I am making a godot addon that integrates gaussian splatting into the editor\/games, as nodes that can be moved\. I have an autoload singleton with a fullscreen quad where the drawing happens\. This works fine when running the game\. However, I am not sure how it would work in the editor, which would be pretty cool\. This way people could see their splat objects also in the editor\. Now I am getting a bunch of errors from the autoload singleton, which would suggest that it is actually loaded in the editor (it is a \@tool script, however I was not sure if that also is enough for autoload singletons to start during edited scenes, it looks like it is)\.

The errors point to the following problem: \
splat\_filenames is empty on line 34, meaning the initialization of the rest of the scene probably happens after that is  called\. It is probably indeed true, since if I close the main demo scene, the errrors keep repeating, suggesting that the autoload tools are loaded before everything, and keep running, even if there is no 3d scene open\.

So my guess for a fix is to make dynamically loading\/unloading splat files possible, and that would possibly solve this as well\. My question is what do you think of all of this, and also do you know if the autoload tool is only the script running, or the attached MeshInstance3D will also be available in the editor in case a 3d scene is opened, rendering the splat objects hopefully in the right place, as they do during running the scene?

], [...
```
But I'd want to include it so that I can pass the texts as arrays to the typst array we had above to use the function to put it into the table. How to do that? Here is the current python script, and how the main.typ looks like now:
```
#show: appendix.with(
  used-ai: true,
  ai-usage: (
    (
      category: [Új ötletek, megoldási javaslatok és programkód generálása],
      tool: [ChatGPT, Gemini],
      parts: [@onallo-munka-bemutatasa\-@plugin-alkalmazasai-fejezet. fejezet],
      share: [25%],
      prompts: [_Az ezen táblázatról szóló szabály meghozása előtt a projekthez használt promptok nem kerültek mentésre. Ezek viszonylag kis, specifikus kérések voltak, kis hatással._
    
    
    ],
    #include "prompts.typ"
    ),
....
```
but ofc this doesn't work :/],
      ),
    ),
  ),
  total-share: [15%],
  total-justification: [
    A generatív MI eszközök sokat segítettek a logika programkódra történő fordításakor, egyes esetekben megoldási ötletek javaslásakor. A megoldási ötleteket minden esetben értelmeztem, és egyes esetekben felülbíráltam. A generált programkódokat átnéztem, kijavítottam, a rendszer logikáját minden esetben értem. A diplomaterv szövegét generatív MI nélkül írtam, az általam befektetett energiát előtérbe helyezve.
  ],
)


= Kérdések az első verzióhoz

- Fejezetek sorrendje, aránya jó-e?
- Van-e valami, amit fejtsek ki bővebben?
- Megvan a szükséges mennyiség?
- Összességében egyéb javaslat?
- Két oldalasra szeretném mindenképpen, mennyire baj?
- AI táblázat mérete maradhat-e? Betűméret mennyire baj? Egyébként nagyon sok helyet foglalna.

= További teendők a Dipterv 2-ig (végleges doksi leadásig)

TODO-k kijavítása, eltüntetése itt is és a kódban is

minden kép, táblázat és kódrészlet be van számozva? és rendesen referálva? A képaláírásokat mindenhol megcsináltam helyesen?

TODO margó tükrözés rendesen, ha 2 oldalasat szeretnék, és a feladatkiíráshoz is a megfelelő margó! Illetve a legvégén: jól legyenek párosítva az oldalak, ha tényleg 2 oldalasat csinálok (tartalomjegyzék-tartalomjegyzék, absztrakt-abstract, stb.)

TODO Daninak a sablonban levő módosításokat elküldeni, ha már kb fix
 
TODO minden bibliography item fel lett használva valahol? footnote vs bibliography jól van kb elválasztva? (nincs többször ugyanaz a footnote, de a bibliography-k tényleg fontos h bibliography-k legyenek?)

TODO GH readme-be, illetve doksiba is (?) beírni, hogy melyik branch-en mi van. cleanup a githubon is, hogy értelmesen, jól nézzen ki. Fontos, leírtam h a readmeben olvasható h melyik branchen mi van! Plusz prezentációt is feltölteni majd!!!
whenhamstersattacktd gpl vs mit??? valahogy feloldani a readmevel, gpl-é tenni a portot

Az egészet beadni AI-nak pl nyelvtani javításra (egy random helyen eglépelni, hogy észreveszi-e!!!)

kódrészletek ne legyenek nagyon durván félbevágva (főleg a kis kódrészletek), meg képek miatt ne legyenek óriási szóközök. Ezt miután már nem lesz tartalmi változás. Kell-e egyáltalán a kódrészletek szétszedhetősége???

időben elküldeni az egészet reviewra (pl november eleje-közepe) (tartalmilag minden benne van-e aminek kell, sorrend/struktúra értelmes-e, kilogrammra elég-e, bármi szakmai pontosítanivaló/kirívóan rossz megfogalmazás)

megkérdezni Mártont h jó-e 2 oldalasra, ha mindenképp úgy szeretném

tervezett ütemterv:
- AI táblázat betétele
- újra végigfutni mindenen, absztraktok, dolgozat szerkezete, egyéb TODO-k letisztázása
- képaláírások, kódaláírások rendben vannak? sehol sincs copy-paste ami nem oda tartozik?
- AI nyelvtani korrekció tesztje (viabilis megoldás-e, minél több hiba, magyartalan szöveg javítása)
- fentebbi todo-k átfutása, hogy van-e valami releváns
- elküldeni a konzulensnek, még mivel érdemes kiegészíteni, átrendezés, ilyesmi stb.
- újabb nyelvtani ellenőrzés
- a/az az ábráknál / fejezetcímeknél kifejezetten! ezt már miután semmi átrendezés / új beszúrás nincs
- valamit tartalmilag / nyelvtanilag totál elírni, hogy azt megtalálja-e egy AI, hha valahol totál marhaság lenne
- a teljes online mappát átmásolni a git-es mappába, és megnézni h kimaradt-e vmi (pl kép) a verziókontrollból

beadás után nyomtatás, + a diasor elkészítése míg amíg jól emlékszem a dokumentumra!


ötletek a méret növelésére:
- nerf megemlítése / kijjebb fejtése
- irodalomkutatáshoz screenshotok, kipróbálni a dolgokat amiket referálok, illetve még írni róluk
- commit history-t, ai chat history-t, teams chatet visszaolvasni, hogy ne hagyjak ki semmit, amiről lehet írni


// vim:spelllang=hu:spell
