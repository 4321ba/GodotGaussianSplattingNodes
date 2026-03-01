# GodotGaussianSplattingNodes

Allows developers to use gaussian splatting objects as they would use a regular mesh + mesh instance.

This is a work in progress master thesis project.

For the previous work which this project is based on, see [this](https://github.com/4321ba/GodotGaussianSplattingGame/tree/vitavehicle) repo, which in turn was based on the [GodotGaussianSplatting](https://github.com/2Retr0/GodotGaussianSplatting) project.

## Todo list

- AI USAGE PAPER WHERE/HOW
- make ply files an imported resource
- update engine version to latest (look [here](https://github.com/EdMUK/GodotGaussianSplatting))
- make editor lag less when this thing is active, especially when the 3d editor is not rendering, and starts to render, there is a hiccup, and also, it does not refresh often enough
- test on amd hardware, something seems wrong
- fix some kind of memory leak
- publikálni az AssetLib-ben

### Future work list from projlab

A továbbiakban a teljesség igénye nélkül az alábbi fejlesztési lehetőségek végrehajtása lenne előnyös:
- jobb mélység-kombinálás splat és sima mesh között, átlátszóság is jobban (mindkét irányú átlátszóság?: átlátszó splat mögött solid háromszögek és fordítva)
- megvizsgálni másfajta módszert a fullscreenquad helyett, pl direkt belenyúlni a renderelendő képbe?
- `.ply` beolvasott fájl hiányzó property-jeinek 0-kkal feltöltése helyett nem feltölteni a gpu-ra, illetve ahol nem a 0 a helyes, ott is megfelelő érték
- konzultálni a `.ply` fájlformátummal, hogy esetlegesen másmilyen, de helyes fájlokat is be tudjon olvasni
- `.splat` fájl beolvasásának képessége, szabványos formátum beolvasása
- arbitrary mennyiségű modell betöltésének lehetősége, esetleg modellek preloadolása, hogy ne kelljen minden láthatóságváltoztatásnál újra feltölteni, ugyanazon modell ne legyen többször feltöltve a gpu-ra
- újralightolható `.ply` fájlok kezelése
- időben változó fájlok kezelése
- konkrét splates környezetben mindkétféle objektumok, környezetek rekonstrukciója, iitlabor modellje pl?
