# 四房连通Demo · DES-SCENE

使用编辑器原生方块构建四房、通路、遮挡体、宝箱与出口。definition.lua是碰撞/视线/导航数据源，导出的scene.data保存实际原生节点。model/main.glb是未来美术资源，本Demo未制作GLB。

controller.lua只提供地图生命周期；物件专属交互在interactables，生成与整局流程在systems。
