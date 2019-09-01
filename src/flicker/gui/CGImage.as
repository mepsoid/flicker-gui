package flicker.gui {
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * Класс загружаемой картинки
	 * 
	 * @version  1.1.30
	 * @author   meps
	 */
	public class CGImage extends CGInteractive implements IGImage {
		
		// если плейсера нет, то объект по нему не скейлится и не выравнивается
		public function CGImage(src:* = null, name:String = null) {
			mLoad = false;
			mImage = null;
			super(src, name);
			constDefault(CONST_FIT, FIT_NONE); // определить значение по умолчанию для используемой константы
		}
		
		/** Загрузить изображение из файла */
		public function load(path:String):void {
			if (mPath == path) {
				doRefit();
				return;
			}
			removeImage();
			mLoad = true;
			mImage = null;
			mPath = path;
			doState();
			CGImageProxy.instance.load(mPath, this);
		}
		
		/** Удалить изображение */
		public function clear():void {
			CGImageProxy.instance.unload(this);
			removeImage();
			mLoad = false;
			mImage = null;
			mPath = null;
			doState();
		}
		
		/** Обработчик загруженной картинки */
		public function imageUpdate(result:CGImageResult):void {
			if (result.error || !mLoad) {
				// ошибка при загрузке изображения
				removeImage();
				mLoad = false;
				mImage = null;
				doState();
			} else {
				mLoad = false;
				if (!mImage || mImage.bitmapData !== result.raster) {
					removeImage();
					mImage = result.create();
				}
				doState();
				doRefit();
			}
		}
		
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
			if (mLoad)
				return LOAD_STATE;
			return mImage ? SHOW_STATE : EMPTY_STATE;
		}
		
		override protected function onDestroy():void {
			mImage = null;
			super.onDestroy();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Удаление изображения со сцены */
		private function removeImage():void {
			if (!mImage)
				return;
			var parent:DisplayObjectContainer = mImage.parent;
			if (parent)
				parent.removeChild(mImage);
		}
		
		/** Перепозиционирование изображения */
		private function doRefit(event:Event = null):void {
			// вызывается по готовности графики, изменении метода позиционирования, смене состояний
			if (event)
				event.target.removeEventListener(Event.ADDED_TO_STAGE, doRefit);
			var mask:DisplayObject = objectFind(PLACER_ID);
			if (!mask) {
				// отображать некуда
				if (mImage)
					mImage.visible = false;
				return;
			}
			mask.visible = false;
			if (!mImage)
				// отображать нечего
				return;
			mImage.mask = mask;
			var parent:DisplayObjectContainer = mask.parent;
			if (!parent.stage) {
				// принудительное позиционирование по факту размещения родительского элемента на сцене 
				parent.addEventListener(Event.ADDED_TO_STAGE, doRefit, false, 0, true);
				return;
			}
			parent.addChildAt(mImage, parent.getChildIndex(mask) + 1);
			mImage.visible = true;
			var r:Rectangle;
			var w:Number, h:Number, dw:Number, dh:Number, kw:Number, kh:Number;
			var a:Number, b:Number, c:Number, d:Number, ow:Number, oh:Number;
			var p0:Point, pw:Point, ph:Point;
			var tm:Matrix, pm:Matrix;
			var f:String = constGet(CONST_FIT);
			if (FIT_ALL == f) {
				// пропорционально заполнить плейсер по максимальному размеру
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
				if (mRect)
					r = mRect;
				else
					r = mImage.getBounds(null);
				kw = r.width / dw;
				kh = r.height / dh;
				if (kw > kh) {
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
				// матрица преобразования изображения относительно родительского контейнера
				/*
				pm = parent.transform.concatenatedMatrix;
				pm.invert();
				tm.concat(pm);
				*/
				mImage.transform.matrix = tm;
			} else if (FIT_FILL == f) {
				// пропорционально заполнить плейсер по минимуму, плейсер является маской
				// алгоритм намеренно переведен к примитивному, чтобы можно было накладывать анимацию поверх вписанного изображения
				r = mask.getBounds(parent); // собственные размеры плейсера
				w = r.width;
				h = r.height;
				p0 = new Point(r.left, r.top);
				if (mRect)
					r = mRect;
				else
					r = mImage.getBounds(null);
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
				// матрица преобразования изображения относительно родительского контейнера
				/*
				pm = parent.transform.concatenatedMatrix;
				pm.invert();
				tm.concat(pm);
				*/
				mImage.transform.matrix = tm;
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
				if (mRect)
					r = mRect;
				else
					r = mImage.getBounds(null);
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
				// матрица преобразования изображения относительно родительского контейнера
				/*
				pm = parent.transform.concatenatedMatrix;
				pm.invert();
				tm.concat(pm);
				*/
				mImage.transform.matrix = tm;
			} else if (FIT_LOCK == f) {
				// ...
			} else {
				mImage.transform.matrix = new Matrix();
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
		private var mLoad:Boolean;
		
		/** Виртуальный прямоугольник размеров изображения */
		private var mRect:Rectangle;
		
		/** Собственный экземпляр изображения */
		private var mImage:Bitmap;
		
		/** Путь к изображению */
		private var mPath:String;
		
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
