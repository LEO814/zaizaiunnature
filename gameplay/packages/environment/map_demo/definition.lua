-- Native whitebox layout. Geometry and navigation read this same definition.
return {
 schemaVersion='0.2.0',id='map_demo',type='environment',displayName='四房连通Demo',
 spawn={x=-2,y=0.1,z=-2},exit={x=-2,y=0.05,z=-1},chest={x=1,y=0.5,z=-1},
 monsterSpawn={x=8,y=0.05,z=8},
 patrolRoute={{x=8,y=0.05,z=8},{x=12,y=0.05,z=8},{x=12,y=0.05,z=12},{x=8,y=0.05,z=12}},
 rooms={{id='entry',label='入口 / 撤离',x=0,z=0},{id='supply',label='补给房',x=10,z=0},{id='hall',label='连接前厅',x=0,z=10},{id='monster',label='墨潮巡猎室',x=10,z=10}},
 bounds={min_x=-4.6,max_x=14.6,min_z=-4.6,max_z=14.6},
 walls={
  {name='wall_west',x=-5,z=5,sx=0.35,sz=20},{name='wall_east',x=15,z=5,sx=0.35,sz=20},
  {name='wall_south',x=5,z=-5,sx=20,sz=0.35},{name='wall_north',x=5,z=15,sx=20,sz=0.35},
  {name='divider_x_south',x=5,z=-2.5,sx=0.35,sz=5},{name='divider_x_mid',x=5,z=5,sx=0.35,sz=5},{name='divider_x_north',x=5,z=12.5,sx=0.35,sz=5},
  {name='divider_z_west',x=-2.5,z=5,sx=5,sz=0.35},{name='divider_z_mid',x=5,z=5,sx=5,sz=0.35},{name='divider_z_east',x=12.5,z=5,sx=5,sz=0.35},
  {name='sight_cover',x=10,z=10,sx=1.2,sz=1.2},
 },
}
