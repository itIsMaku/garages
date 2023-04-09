/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

CREATE TABLE IF NOT EXISTS `garages` (
  `id` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `coords` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`coords`)),
  `display_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `blip` int(11) NOT NULL DEFAULT 0,
  `zone_radius` longtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'car',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*!40000 ALTER TABLE `garages` DISABLE KEYS */;
INSERT INTO `garages` (`id`, `coords`, `display_name`, `blip`, `zone_radius`, `type`) VALUES
	('Abrakebabra', '{"x":-1259.218505859375,"y":-1226.387451171875,"z":5.38210010528564,"w":106.8010025024414}', 'Abrakebabra', 0, '{"height":3,"width":3}', 'car'),
	('Bahamas West Mamas', '{"x":-1436.1539306640626,"y":-584.67041015625,"z":30.652099609375,"w":206.62680053710938}', 'Bahamas West Mamas', 0, '{"height":3,"width":3}', 'car'),
	('Bennys', '{"x":-184.76780700683595,"y":-1289.79638671875,"z":31.29649925231933,"w":175.160400390625}', 'Bennys', 0, '{"height":3,"width":3}', 'car'),
	('Brouge Ave', '{"x":139.48570251464845,"y":-1868.89990234375,"z":24.17070007324218,"w":157.53810119628907}', 'Brouge Ave', 0, '{"height":3,"width":3}', 'car'),
	('Covenant Ave', '{"x":137.92210388183595,"y":-1893.031005859375,"z":23.35309982299804,"w":334.4718017578125}', 'Covenant Ave', 0, '{"height":3,"width":3}', 'car'),
	('Dálnice', '{"x":-2964.9599609375,"y":372.07000732421877,"z":14.77999973297119,"w":86.06999969482422}', 'Dálnice', 1, '{"height":3,"width":3}', 'car'),
	('Davis Ave', '{"x":-222.4687957763672,"y":-1698.3931884765626,"z":34.02780151367187,"w":291.44281005859377}', 'Davis Ave', 0, '{"height":3,"width":3}', 'car'),
	('Downtown', '{"x":-66.51000213623047,"y":-1828.010009765625,"z":26.94000053405761,"w":235.63999938964845}', 'Downtown', 0, '{"height":3,"width":3}', 'car'),
	('Dutch London St', '{"x":-7.51550006866455,"y":-1542.1558837890626,"z":29.30050086975097,"w":227.54190063476563}', 'Dutch London St', 0, '{"height":3,"width":3}', 'car'),
	('EMS - St. Fiacre Hospital', '{"x":1166.0941162109376,"y":-1541.5953369140626,"z":34.69260025024414,"w":269.62701416015627}', 'EMS - St. Fiacre Hospital', 0, '{"height":5,"width":5}', 'car'),
	('Exotics Autos', '{"x":531.8673095703125,"y":-175.07870483398438,"z":53.86220169067383,"w":180.43020629882813}', 'Exotics Autos', 0, '{"height":3,"width":3}', 'car'),
	('Galaxy Night Club', '{"x":367.210205078125,"y":294.87310791015627,"z":103.41449737548828,"w":345.2149963378906}', 'Galaxy Night Club', 0, '{"height":3,"width":3}', 'car'),
	('Golf Resort', '{"x":-1394.589599609375,"y":37.58430099487305,"z":53.41730117797851,"w":4.28410005569458}', 'Golf Resort', 0, '{"height":3,"width":3}', 'car'),
	('Grapeseed', '{"x":1696.7528076171876,"y":4939.998046875,"z":42.1068000793457,"w":55.5640983581543}', 'Grapeseed', 1, '{"height":3,"width":3}', 'car'),
	('Grove St v1', '{"x":42.8119010925293,"y":-1853.5103759765626,"z":22.83149909973144,"w":133.0438995361328}', 'Grove St v1', 0, '{"height":3,"width":3}', 'car'),
	('Grove St v2', '{"x":0.7761999964714,"y":-1877.4466552734376,"z":23.70459938049316,"w":318.20208740234377}', 'Grove St v2', 0, '{"height":3,"width":3}', 'car'),
	('Hlavní garáž', '{"x":212.4199981689453,"y":-798.77001953125,"z":30.8799991607666,"w":336.6099853515625}', 'Hlavní garáž', 1, '{"height":10,"width":10}', 'car'),
	('Jamestown St', '{"x":478.7001037597656,"y":-1777.41064453125,"z":28.62220001220703,"w":277.5473937988281}', 'Jamestown St', 0, '{"height":3,"width":3}', 'car'),
	('La Puerta', '{"x":-972.0460205078125,"y":-1463.9659423828126,"z":5.01590013504028,"w":108.45089721679688}', 'La Puerta', 0, '{"height":3,"width":3}', 'car'),
	('Little Seoul', '{"x":-696.3496704101563,"y":-984.5140991210938,"z":20.39019966125488,"w":359.8030090332031}', 'Little Seoul', 0, '{"height":3,"width":3}', 'car'),
	('LSPD - Mission Row', '{"x":407.91448974609377,"y":-984.3126831054688,"z":28.6599006652832,"w":230.8249053955078}', 'LSPD - Mission Row', 0, '{"height":3,"width":3}', 'car'),
	('LSPD - Vespucci', '{"x":-1116.2532958984376,"y":-806.76611328125,"z":17.17110061645507,"w":241.85699462890626}', 'LSPD - Vespucci', 0, '{"height":3,"width":3}', 'car'),
	('LSPD - Vespucci v2', '{"x":-1049.62939453125,"y":-863.9489135742188,"z":5.02689981460571,"w":60.6604995727539}', 'LSPD - Vespucci v2', 0, '{"height":3,"width":3}', 'car'),
	('LSSD - Sandy Shores', '{"x":1808.4395751953126,"y":3662.4697265625,"z":34.26240158081055,"w":329.9273986816406}', 'LSSD - Sandy Shores', 0, '{"height":3,"width":3}', 'car'),
	('Luxury Auto', '{"x":-788.6143798828125,"y":-198.16619873046876,"z":37.28359985351562,"w":298.49798583984377}', 'Luxury Auto', 0, '{"height":3,"width":3}', 'car'),
	('Macdonnald St', '{"x":253.21209716796876,"y":-1683.6363525390626,"z":29.21960067749023,"w":227.02340698242188}', 'Macdonnald St', 0, '{"height":3,"width":3}', 'car'),
	('Maggelan Ave', '{"x":-1252.9127197265626,"y":-1202.4161376953126,"z":7.15689992904663,"w":11.73690032958984}', 'Maggelan Ave', 0, '{"height":3,"width":3}', 'car'),
	('Maják', '{"x":3333.19189453125,"y":5160.18798828125,"z":18.30739974975586,"w":155.543701171875}', 'Maják', 0, '{"height":3,"width":3}', 'car'),
	('Marlowe Vineyard', '{"x":-1909.5460205078126,"y":2052.825439453125,"z":140.7373046875,"w":168.51260375976563}', 'Marlowe Vineyard', 0, '{"height":3,"width":3}', 'car'),
	('Mayans - Motorcycle Club', '{"x":894.9208984375,"y":3588.109130859375,"z":33.28910064697265,"w":266.3467102050781}', 'Mayans - Motorcycle Club', 0, '{"height":1,"width":1}', 'car'),
	('Mirror Park', '{"x":1039.5906982421876,"y":-772.1384887695313,"z":58.01639938354492,"w":192.49569702148438}', 'Mirror Park', 1, '{"height":3,"width":3}', 'car'),
	('Moore Papers', '{"x":1209.04443359375,"y":1816.9072265625,"z":78.93299865722656,"w":29.02770042419433}', 'Moore Papers', 0, '{"height":3,"width":3}', 'car'),
	('Osobní garáž #1', '{"x":-176.6822967529297,"y":963.2166137695313,"z":236.53390502929688,"w":304.6778869628906}', 'Osobní garáž #1', 0, '{"height":2,"width":2}', 'car'),
	('Osobní garáž #10', '{"x":-1527.638427734375,"y":73.90850067138672,"z":56.76200103759765,"w":7.55490016937255}', 'Osobní garáž #10', 0, '{"height":2,"width":2}', 'car'),
	('Osobní garáž #11', '{"x":-676.8189697265625,"y":903.6743774414063,"z":230.55799865722657,"w":329.57720947265627}', 'Osobní garáž #11', 0, '{"height":2,"width":2}', 'car'),
	('Osobní garáž #12', '{"x":-887.4517822265625,"y":357.1590881347656,"z":84.87629699707031,"w":4.33529996871948}', 'Osobní garáž #12', 0, '{"height":2,"width":2}', 'car'),
	('Osobní garáž #13', '{"x":-811.75341796875,"y":187.30709838867188,"z":72.4749984741211,"w":111.4302978515625}', 'Osobní garáž #13', 0, '{"height":2,"width":2}', 'car'),
	('Osobní garáž #14', '{"x":-1575.2650146484376,"y":-77.68659973144531,"z":54.13529968261719,"w":272.9212951660156}', 'Osobní garáž #14', 0, '{"height":2,"width":2}', 'car'),
	('Osobní garáž #15', '{"x":-1185.4989013671876,"y":902.8665161132813,"z":195.6278076171875,"w":25.2677993774414}', 'Osobní garáž #15', 0, '{"height":2,"width":2}', 'car'),
	('Osobní garáž #16', '{"x":-710.090087890625,"y":642.3845825195313,"z":155.17520141601563,"w":347.080810546875}', 'Osobní garáž #16', 0, '{"height":2,"width":2}', 'car'),
	('Osobní garáž #17', '{"x":-527.5175170898438,"y":529.1926879882813,"z":111.8499984741211,"w":43.85279846191406}', 'Osobní garáž #17', 0, '{"height":2,"width":2}', 'car'),
	('Osobní garáž #18', '{"x":-95.97709655761719,"y":825.1132202148438,"z":235.72799682617188,"w":97.58429718017578}', 'Osobní garáž #18', 0, '{"height":1,"width":1}', 'car'),
	('Osobní garáž #19', '{"x":-1093.29736328125,"y":4944.4326171875,"z":218.33929443359376,"w":155.6417999267578}', 'Osobní garáž #19', 0, '{"height":1,"width":1}', 'car'),
	('Osobní garáž #2', '{"x":-142.5847930908203,"y":896.5062866210938,"z":235.6553955078125,"w":318.56768798828127}', 'Osobní garáž #2', 0, '{"height":2,"width":2}', 'car'),
	('Osobní garáž #20', '{"x":810.4249877929688,"y":2178.263916015625,"z":52.50350189208984,"w":335.2196044921875}', 'Osobní garáž #20', 0, '{"height":1,"width":1}', 'car'),
	('Osobní garáž #21', '{"x":-770.9852294921875,"y":-916.8201293945313,"z":17.5447998046875,"w":355.40838623046877}', 'Osobní garáž #21', 0, '{"height":1,"width":1}', 'car'),
	('Osobní garáž #22', '{"x":914.21728515625,"y":-490.0907897949219,"z":59.02199935913086,"w":205.0634002685547}', 'Osobní garáž #22', 0, '{"height":2,"width":2}', 'car'),
	('Osobní garáž #23', '{"x":224.39129638671876,"y":753.394287109375,"z":204.85609436035157,"w":65.34739685058594}', 'Osobní garáž #23', 0, '{"height":2,"width":2}', 'car'),
	('Osobní garáž #3', '{"x":2424.755859375,"y":5002.52783203125,"z":46.30440139770508,"w":134.59080505371095}', 'Osobní garáž #3', 0, '{"height":2,"width":2}', 'car'),
	('Osobní garáž #4', '{"x":-1782.78173828125,"y":464.4678955078125,"z":128.3076934814453,"w":106.10700225830078}', 'Osobní garáž #4', 0, '{"height":2,"width":2}', 'car'),
	('Osobní garáž #5', '{"x":-1460.235107421875,"y":-47.1713981628418,"z":54.67620086669922,"w":216.25120544433595}', 'Osobní garáž #5', 0, '{"height":2,"width":2}', 'car'),
	('Osobní garáž #6', '{"x":-2596.75927734375,"y":1922.1878662109376,"z":167.2982940673828,"w":5.4148998260498}', 'Osobní garáž #6', 0, '{"height":2,"width":2}', 'car'),
	('Osobní garáž #7', '{"x":-2786.248779296875,"y":1432.250732421875,"z":100.92829895019531,"w":235.69659423828126}', 'Osobní garáž #7', 0, '{"height":2,"width":2}', 'car'),
	('Osobní garáž #8', '{"x":-1548.0975341796876,"y":882.5372924804688,"z":181.29530334472657,"w":199.61090087890626}', 'Osobní garáž #8', 0, '{"height":2,"width":2}', 'car'),
	('Osobní garáž #9', '{"x":353.5544128417969,"y":-4.75299978256225,"z":82.997802734375,"w":220.12879943847657}', 'Osobní garáž #9', 0, '{"height":2,"width":2}', 'car'),
	('Ottos Auto', '{"x":815.6146850585938,"y":-827.590087890625,"z":26.18440055847168,"w":359.6767883300781}', 'Ottos Auto', 0, '{"height":3,"width":3}', 'car'),
	('Pacific Bluffs Resort', '{"x":-3023.074951171875,"y":93.58200073242188,"z":11.61170005798339,"w":316.5857849121094}', 'Pacific Bluffs Resort', 0, '{"height":3,"width":3}', 'car'),
	('Paleto Fix', '{"x":110.83999633789063,"y":6607.81982421875,"z":31.86000061035156,"w":265.2799987792969}', 'Paleto Fix', 1, '{"height":10,"width":10}', 'car'),
	('Pink Cage Motel', '{"x":324.4613952636719,"y":-212.55360412597657,"z":54.08660125732422,"w":338.4346008300781}', 'Pink Cage Motel', 0, '{"height":5,"width":5}', 'car'),
	('Pizzeria', '{"x":799.951171875,"y":-733.3939819335938,"z":27.6732006072998,"w":92.32170104980469}', 'Pizzeria', 0, '{"height":3,"width":3}', 'car'),
	('Pláž', '{"x":-1191.92138671875,"y":-1493.960693359375,"z":4.3797001838684,"w":215.14720153808595}', 'Pláž', 1, '{"height":3,"width":3}', 'car'),
	('Podzemní garáž Fire Deparment', '{"x":-599.3419799804688,"y":-116.06400299072266,"z":33.75450134277344,"w":226.34410095214845}', 'Podzemní garáž Fire Deparment', 0, '{"height":2,"width":2}', 'car'),
	('Premium Deluxe Motorsport', '{"x":-14.35009956359863,"y":-1094.3616943359376,"z":26.67620086669922,"w":159.06129455566407}', 'Premium Deluxe Motorsport', 0, '{"height":3,"width":3}', 'car'),
	('Ray lowenstein Blvd', '{"x":358.2428894042969,"y":-1804.9268798828126,"z":28.94809913635254,"w":50.41469955444336}', 'Ray lowenstein Blvd', 0, '{"height":3,"width":3}', 'car'),
	('Roy Lowenstein Blvd', '{"x":470.00628662109377,"y":-1577.3275146484376,"z":29.12260055541992,"w":228.26019287109376}', 'Roy Lowenstein Blvd', 0, '{"height":3,"width":3}', 'car'),
	('Salieri Bar', '{"x":401.1741027832031,"y":-1497.393798828125,"z":29.29129981994629,"w":29.62089920043945}', 'Salieri Bar', 0, '{"height":3,"width":3}', 'car'),
	('Sandy Fix', '{"x":1167.470703125,"y":2656.97021484375,"z":38.03189849853515,"w":270.14068603515627}', 'Sandy Fix', 0, '{"height":3,"width":3}', 'car'),
	('Santos - Motorcycle Club', '{"x":2504.8876953125,"y":4076.602783203125,"z":38.63140106201172,"w":59.31779861450195}', 'Santos - Motorcycle Club', 0, '{"height":1,"width":1}', 'car'),
	('Starlite Motel', '{"x":963.4957885742188,"y":-199.7064971923828,"z":73.10150146484375,"w":330.1614074707031}', 'Starlite Motel', 0, '{"height":5,"width":5}', 'car'),
	('Strawberry Ave', '{"x":-23.93449974060058,"y":-1438.7080078125,"z":30.65320014953613,"w":175.83070373535157}', 'Strawberry Ave', 0, '{"height":3,"width":3}', 'car'),
	('Strawberry Ave v2', '{"x":280.59210205078127,"y":-2077.9951171875,"z":16.87689971923828,"w":105.63330078125}', 'Strawberry Ave v2', 0, '{"height":3,"width":3}', 'car'),
	('Tequila-la', '{"x":-565.6431884765625,"y":327.69439697265627,"z":84.41580200195313,"w":263.55499267578127}', 'Tequila-la', 0, '{"height":3,"width":3}', 'car'),
	('The Belmond Bar', '{"x":-1324.0550537109376,"y":-1135.955078125,"z":4.40010023117065,"w":177.57659912109376}', 'The Belmond Bar', 0, '{"height":3,"width":3}', 'car'),
	('UwU Cat Caffe', '{"x":-580.9050903320313,"y":-1091.349365234375,"z":22.17880058288574,"w":88.17729949951172}', 'UwU Cat Caffe', 0, '{"height":3,"width":3}', 'car'),
	('Vanilla Unicorn', '{"x":149.673095703125,"y":-1308.3175048828126,"z":29.20229911804199,"w":54.0177993774414}', 'Vanilla Unicorn', 0, '{"height":3,"width":3}', 'car'),
	('Vespucci Beach', '{"x":-1125.3505859375,"y":-1609.9027099609376,"z":4.3983998298645,"w":305.3454895019531}', 'Vespucci Beach', 0, '{"height":3,"width":3}', 'car'),
	('Věznice Bolingbroke', '{"x":1862.400390625,"y":2584.548583984375,"z":45.67269897460937,"w":357.576904296875}', 'Věznice Bolingbroke', 0, '{"height":5,"width":5}', 'car'),
	('Vinewood Hills', '{"x":-69.29460144042969,"y":897.6179809570313,"z":235.56390380859376,"w":115.20870208740235}', 'Vinewood Hills', 1, '{"height":3,"width":3}', 'car'),
	('Von Crastenburg Hotel', '{"x":-1222.4407958984376,"y":-182.02659606933595,"z":39.17129898071289,"w":124.53669738769531}', 'Von Crastenburg Hotel', 0, '{"height":5,"width":5}', 'car'),
	('Weazel News', '{"x":-620.5808715820313,"y":-927.4884033203125,"z":22.76759910583496,"w":357.2134094238281}', 'Weazel News', 0, '{"height":3,"width":3}', 'car'),
	('West eclipse Blvd', '{"x":-1571.9915771484376,"y":-246.35350036621095,"z":49.49530029296875,"w":160.3105010986328}', 'West eclipse Blvd', 0, '{"height":3,"width":3}', 'car'),
	('Yellow Jack', '{"x":2006.68017578125,"y":3055.496826171875,"z":47.04970169067383,"w":55.20380020141601}', 'Yellow Jack', 0, '{"height":3,"width":3}', 'car');
/*!40000 ALTER TABLE `garages` ENABLE KEYS */;

CREATE TABLE IF NOT EXISTS `garages_categories` (
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `parent` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `job` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `restriction` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'car'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `garages_jobs` (
  `job` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `grade` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;

ALTER TABLE `owned_vehicles`
	ADD COLUMN `model` VARCHAR(50) NULL DEFAULT NULL AFTER `plate`,
	ADD COLUMN `garage` VARCHAR(50) NULL DEFAULT NULL AFTER `mdt_description`,
	ADD COLUMN `category` VARCHAR(50) NULL DEFAULT NULL AFTER `mdt_description`;