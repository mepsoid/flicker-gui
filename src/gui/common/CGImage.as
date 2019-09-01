package ui.common {
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.PixelSnapping;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;
	
	/**
	 * Класс загружаемой картинки
	 * 
	 * @version  1.1.26
	 * @author   meps
	 */
	public class CGImage extends CGInteractive {
		
		// если плейсера нет, то объект по нему не скейлится и не выравнивается
		public function CGImage(src:* = null, name:String = null) {
			m_load = false;
			m_image = null;
			super(src, name);
			constDefault(CONST_FIT, FIT_NONE); // определить значение по умолчанию для используемой константы
		}
		
		/** Загрузить изображение из файла */
		public function load(path:String):void {
			//log.write("#", "CGImage::load", url, m_url);
			if (m_path == path) {
				doRefit();
				return;
			}
			removeImage();
			m_load = true;
			m_image = null;
			m_path = path;
			doState();
			CGImageProxy.instance.load(m_path, onImageLoad);
		}
		
		/** Удалить изображение */
		public function clear():void {
			removeImage();
			m_load = false;
			m_image = null;
			m_path = null;
			doState();
		}
		
		/** Задать виртуальный прямоугольник, соответствующий изображению */
		/*
		public function sizeVirtual(rect:Rectangle):void {
			if (rect) {
				if (m_rect && rect.equals(m_rect))
					return;
				m_rect = rect;
				doRefit();
			} else if (m_rect) {
				m_rect = null;
				doRefit();
			}
		}
		*/
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function onClipAppend(mc:MovieClip):void {
			super.onClipAppend(mc);
			doRefit();
		}
		
		override protected function onClipParent():void {
			super.onClipParent();
			doRefit();
		}
		
		override protected function doStateValue():String {
			if (m_load)
				return LOAD_STATE;
			return m_image ? SHOW_STATE : EMPTY_STATE;
		}
		
		override protected function onDestroy():void {
			m_image = null;
			super.onDestroy();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Обработчик загруженной картинки */
		private function onImageLoad(image:CGImageResult):void {
			m_load = false;
			if (image.error) {
				// ошибка при загрузке изображения
				m_image = null;
				doState();
			} else {
				var img:DisplayObject = image.data;
				if (img !== m_image) {
					removeImage();
					m_image = img;
				}
				doState();
				doRefit();
			}
		}
		
		/** Удаление изображения со сцены */
		private function removeImage():void {
			if (!m_image)
				return;
			var parent:DisplayObjectContainer = m_image.parent;
			if (parent)
				parent.removeChild(m_image);
		}
		
		/** Перепозиционирование изображения */
		private function doRefit(event:Event = null):void {
			// вызывается по готовности графики, изменении метода позиционирования, смене состояний
			if (event)
				event.target.removeEventListener(Event.ADDED_TO_STAGE, doRefit);
			var mask:DisplayObject = objectFind(PLACER_ID);
			if (!mask) {
				// отображать некуда
				if (m_image)
					m_image.visible = false;
				return;
			}
			mask.visible = false;
			if (!m_image)
				// отображать нечего
				return;
			var parent:DisplayObjectContainer = mask.parent;
			if (!parent.stage) {
				// принудительное позиционирование по факту размещения родительского элемента на сцене 
				parent.addEventListener(Event.ADDED_TO_STAGE, doRefit, false, 0, true);
				return;
			}
			parent.addChildAt(m_image, parent.getChildIndex(mask) + 1);
			m_image.visible = true;
			m_image.mask = mask;
			var r:Rectangle;
			var w:Number, h:Number, dw:Number, dh:Number, kw:Number, kh:Number;
			var a:Number, b:Number, c:Number, d:Number, ow:Number, oh:Number;
			var p0:Point, pw:Point, ph:Point;
			var tm:Matrix, pm:Matrix;
			var f:String = constGet(CONST_FIT);
			//log.write(p.stage ? "#" : "!", "CGImage::onRefit", f, m, m_url, m_image, m_image.getBounds(null), p.stage);
			if (FIT_ALL == f) {
				// пропорционально заполнить плейсер по максимальному размеру
				r = mask.getBounds(parent); // собственные размеры плейсера
				//log.write("!", "placer:", r);
				w = r.width;
				h = r.height;
				p0 = new Point(r.left, r.top);
				pw = new Point(r.right, r.top);
				ph = new Point(r.left, r.bottom);
				// положение задающих плейсер вершин в глобальных координатах
				p0 = mask.localToGlobal(p0);
				pw = mask.localToGlobal(pw);
				ph = mask.localToGlobal(ph);
				//log.write("!", "p0:", p0, "pw:", pw, "ph:", ph);
				// соотношение сторон параллелограмма плейсера и сторон изображения
				dw = distPoint(p0, pw);
				dh = distPoint(p0, ph);
				//log.write("!", "dw:", dw, "dh:", dh);
				if (m_rect)
					r = m_rect;
				else
					r = m_image.getBounds(null);
				//log.write("!", "img:", r, m_rect);
				kw = r.width / dw;
				kh = r.height / dh;
				if (kw > kh) {
					kh = r.height * kw / kh;
					kw = r.width;
				} else {
					kw = r.width * kh / kw;
					kh = r.height;
				}
				//log.write("!", "kw:", kw, "kh:", kh);
				// коэффициенты матрицы переводящей плейсер в его текущую позицию
				a = (pw.x - p0.x) / kw;
				b = (pw.y - p0.y) / kw;
				c = (ph.x - p0.x) / kh;
				d = (ph.y - p0.y) / kh;
				// смещение картинки для выравнивания по центру
				ow = ((kw - r.width) * a + (kh - r.height) * c) * 0.5;
				oh = ((kw - r.width) * b + (kh - r.height) * d) * 0.5;
				tm = new Matrix(
					a, b,
					c, d,
					p0.x + ow - r.left, p0.y + oh - r.top
				);
				// вычисленная вручную матрица преобразования
				pm = parent.transform.matrix;
				while ((parent = parent.parent) != null)
					pm.concat(parent.transform.matrix);
				pm.invert();
				tm.concat(pm);
				//log.write("!", "cycle matrix:", tm);
				// матрица преобразования изображения относительно родительского контейнера
				/*
				pm = parent.transform.concatenatedMatrix;
				pm.invert();
				tm.concat(pm);
				log.write("!", "concat matrix:", tm);
				*/
				m_image.transform.matrix = tm;
			} else if (FIT_FILL == f) {
				// пропорционально заполнить плейсер по минимуму, плейсер является маской
				// алгоритм намеренно переведен к примитивному, чтобы можно было накладывать анимацию поверх вписанного изображения
				r = mask.getBounds(parent); // собственные размеры плейсера
				w = r.width;
				h = r.height;
				p0 = new Point(r.left, r.top);
				if (m_rect)
					r = m_rect;
				else
					r = m_image.getBounds(null);
				kw = w / r.width;
				kh = h / r.height;
				if (kw > kh)
					kh = kw;
				// смещение картинки для выравнивания по центру
				ow = (w - r.width * kh) * 0.5;
				oh = (h - r.height * kh) * 0.5;
				tm = new Matrix(
					kh, 0,
					0, kh,
					p0.x + ow, p0.y + oh
				);
				/*
				p0 = new Point(r.left, r.top);
				pw = new Point(r.right, r.top);
				ph = new Point(r.left, r.bottom);
				// положение задающих плейсер вершин в глобальных координатах
				p0 = mask.localToGlobal(p0);
				pw = mask.localToGlobal(pw);
				ph = mask.localToGlobal(ph);
				// соотношение сторон параллелограмма плейсера и сторон изображения
				dw = distPoint(p0, pw);
				dh = distPoint(p0, ph);
				if (m_rect)
					r = m_rect;
				else
					r = m_image.getBounds(null);
				kw = r.width / dw;
				kh = r.height / dh;
				if (kw < kh) {
					kh = r.height * kw / kh;
					kw = r.width;
				} else {
					kw = r.width * kh / kw;
					kh = r.height;
				}
				// коэффициенты матрицы переводящей плейсер в его текущую позицию
				a = (pw.x - p0.x) / kw;
				b = (pw.y - p0.y) / kw;
				c = (ph.x - p0.x) / kh;
				d = (ph.y - p0.y) / kh;
				// смещение картинки для выравнивания по центру
				ow = ((kw - r.width) * a + (kh - r.height) * c) * 0.5;
				oh = ((kw - r.width) * b + (kh - r.height) * d) * 0.5;
				tm = new Matrix(
					a, b,
					c, d,
					p0.x + ow - r.left, p0.y + oh - r.top
				);
				// вычисленная вручную матрица преобразования
				pm = parent.transform.matrix;
				while ((parent = parent.parent) != null)
					pm.concat(parent.transform.matrix);
				pm.invert();
				tm.concat(pm);
				*/
				//log.write("!", "cycle matrix:", tm);
				// матрица преобразования изображения относительно родительского контейнера
				/*
				pm = parent.transform.concatenatedMatrix;
				pm.invert();
				tm.concat(pm);
				*/
				m_image.transform.matrix = tm;
			} else if (FIT_EXACT == f) {
				// заполнить весь плейсер
				r = mask.getBounds(parent); // собственные размеры плейсера
				w = r.width;
				h = r.height;
				p0 = new Point(r.left, r.top);
				pw = new Point(r.right, r.top);
				ph = new Point(r.left, r.bottom);
				// положение задающих плейсер вершин в глобальных координатах
				p0 = mask.localToGlobal(p0);
				pw = mask.localToGlobal(pw);
				ph = mask.localToGlobal(ph);
				// соотношение сторон параллелограмма плейсера и сторон изображения
				dw = distPoint(p0, pw);
				dh = distPoint(p0, ph);
				if (m_rect)
					r = m_rect;
				else
					r = m_image.getBounds(null);
				// коэффициенты матрицы переводящей плейсер в его текущую позицию
				a = (pw.x - p0.x) / r.width;
				b = (pw.y - p0.y) / r.width;
				c = (ph.x - p0.x) / r.height;
				d = (ph.y - p0.y) / r.height;
				tm = new Matrix(
					a, b,
					c, d,
					p0.x - r.left, p0.y - r.top
				);
				// вычисленная вручную матрица преобразования
				pm = parent.transform.matrix;
				while ((parent = parent.parent) != null)
					pm.concat(parent.transform.matrix);
				pm.invert();
				tm.concat(pm);
				//log.write("!", "cycle matrix:", tm);
				// матрица преобразования изображения относительно родительского контейнера
				/*
				pm = parent.transform.concatenatedMatrix;
				pm.invert();
				tm.concat(pm);
				*/
				m_image.transform.matrix = tm;
			} else if (FIT_LOCK == f) {
				// ...
			} else {
				m_image.transform.matrix = new Matrix();
			}
		}
		
		/** Расстояние между точками */
		private function distPoint(p1:Point, p2:Point):Number {
			var a:Number = p1.x - p2.x;
			var b:Number = p1.y - p2.y;
			return Math.sqrt(a * a + b * b);
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Флаг процесса загрузки изображения */
		private var m_load:Boolean;
		
		/** Виртуальный прямоугольник размеров изображения */
		private var m_rect:Rectangle;
		
		/** Собственный экземпляр изображения */
		private var m_image:DisplayObject;
		
		/** Путь к изображению */
		private var m_path:String;
		
		private static const PLACER_ID:String  = ".placer";
		private static const CONST_FIT:String  = "fit"; // имя константы
		private static const FIT_NONE:String   = "none";
		private static const FIT_ALL:String    = "all"; // растянуть пропорционально по максимальной стороне
		private static const FIT_FILL:String   = "fill"; // растянуть пропорционально по минимальной стороне
		private static const FIT_EXACT:String  = "exact"; // непропорционально растянуть до всего плейсера
		private static const FIT_LOCK:String   = "lock";
		
		private static const EMPTY_STATE:String = "empty"; // неактивное состояние или ошибка при загрузке
		private static const SHOW_STATE:String = "show"; // состояние отображения картинки
		private static const LOAD_STATE:String = "load"; // состояние ожидания загрузки
		
	}

}
