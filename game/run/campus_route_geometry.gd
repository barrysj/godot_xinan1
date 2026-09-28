extends RefCounted
## Source-image coordinates, shared by every lighting state. Not a navigation mesh.
const CROP = Rect2(200, 260, 1200, 800)
## Continuous exploration envelopes, not cadastral or building footprints.
const AREAS = [
	[Vector2(276,755),Vector2(352,697),Vector2(462,743),Vector2(558,799),Vector2(641,811),Vector2(758,691),Vector2(872,633),Vector2(919,573),Vector2(958,523),Vector2(1037,511),Vector2(1132,558),Vector2(1173,662),Vector2(1170,760),Vector2(1124,828),Vector2(1033,903),Vector2(976,954),Vector2(860,981),Vector2(766,955),Vector2(676,1020),Vector2(582,1001),Vector2(465,939),Vector2(353,886),Vector2(278,829)],
	[Vector2(452,489),Vector2(540,450),Vector2(558,387),Vector2(657,378),Vector2(744,433),Vector2(747,515),Vector2(792,555),Vector2(840,584),Vector2(888,527),Vector2(903,452),Vector2(945,411),Vector2(959,304),Vector2(1068,279),Vector2(1120,309),Vector2(1219,312),Vector2(1251,367),Vector2(1228,439),Vector2(1151,469),Vector2(1105,507),Vector2(1010,516),Vector2(965,511),Vector2(951,561),Vector2(886,628),Vector2(799,723),Vector2(666,892),Vector2(592,865),Vector2(702,715),Vector2(748,638),Vector2(660,584),Vector2(557,593),Vector2(463,563)]
]
const PLACES = {
	"main": {"title": "主楼", "anchor": Vector2(503, 874), "polygon": [Vector2(299,787),Vector2(354,729),Vector2(436,764),Vector2(409,801),Vector2(595,909),Vector2(636,867),Vector2(710,917),Vector2(653,986)]},
	"lake": {"title": "东湖", "anchor": Vector2(956, 819), "polygon": [Vector2(871,673),Vector2(942,699),Vector2(1033,709),Vector2(1084,735),Vector2(1143,758),Vector2(1130,792),Vector2(1076,829),Vector2(1013,876),Vector2(981,913),Vector2(868,953),Vector2(808,932),Vector2(773,896),Vector2(798,846),Vector2(814,814),Vector2(827,762),Vector2(868,730)]},
	"liren": {"title": "立人楼", "anchor": Vector2(1034, 627), "polygon": [Vector2(927,626),Vector2(965,586),Vector2(965,558),Vector2(1005,536),Vector2(1044,535),Vector2(1077,559),Vector2(1072,593),Vector2(1118,592),Vector2(1136,674),Vector2(1040,698)]},
	"library": {"title": "图书馆", "anchor": Vector2(634, 482), "polygon": [Vector2(475,510),Vector2(490,493),Vector2(554,485),Vector2(580,461),Vector2(583,414),Vector2(655,405),Vector2(716,449),Vector2(720,470),Vector2(696,485),Vector2(708,513),Vector2(674,551),Vector2(617,562),Vector2(566,540),Vector2(516,557),Vector2(480,546)]},
	"avenue": {"title": "银杏大道", "anchor": Vector2(774, 706), "polygon": [Vector2(616,846),Vector2(913,533),Vector2(943,553),Vector2(648,867)]},
	"pinxue": {"title": "品学楼", "anchor": Vector2(1092, 397), "polygon": [Vector2(985,324),Vector2(1067,301),Vector2(1093,344),Vector2(1197,334),Vector2(1223,359),Vector2(1215,405),Vector2(1110,434),Vector2(1096,481),Vector2(1021,493),Vector2(994,446),Vector2(1007,420),Vector2(993,392)]}
}
const ROUTES = [
	{"title": "东湖路线", "places": ["main", "lake", "liren"], "summary": "主楼 → 东湖 → 立人楼", "path": [Vector2(540,882),Vector2(642,891),Vector2(727,801),Vector2(783,724),Vector2(842,674),Vector2(924,653),Vector2(1018,708),Vector2(1100,700)]},
	{"title": "银杏路线", "places": ["library", "avenue", "pinxue"], "summary": "图书馆 → 银杏大道 → 品学楼", "path": [Vector2(680,550),Vector2(777,618),Vector2(823,645),Vector2(939,522),Vector2(923,480),Vector2(983,461),Vector2(1093,436)]}
]
