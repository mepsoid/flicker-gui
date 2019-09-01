package framework.gui {
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	import framework.utils.printClass;
	
	/**
	 * Данные о загруженном изображении
	 * 
	 * @version  1.0.7
	 * @author   meps
	 */
	public class CGImageResult {
		
		public function CGImageResult(path:String, data:DisplayObject = null) {
			mTimestamp = getTimer();
			mPath = path;
			if (data is BitmapData) {
				// исходная графика растр
				mRaster = Bitmap(data).bitmapData;
				mError = false;
			} else if (data) {
				// исходная графика рендерится в битмап
				mRaster = new BitmapData(data.width, data.height, true, 0x00000000);
				mRaster.draw(data, null, null, null, null, true);
				mError = false;
			} else {
				// ошибка при загрузке
				mRaster = null;
				mError = true;
			}
		}
		
		/** Путь к изображению */
		public function get path():String {
			return mPath;
		}
		
		/** Растровые данные изображения */
		public function get raster():BitmapData {
			return mRaster;
		}
		
		/** Создать графику на основе растра */
		public function create():Bitmap {
			if (mRaster) {
				var bitmap:Bitmap = new Bitmap(mRaster);
				bitmap.smoothing = true;
				return bitmap;
			}
			// пустой результат; никем не должен запрашиваться
			return null;
		}
		
		/** Флаг успешной загрузки изображения */
		public function get error():Boolean {
			return mError;
		}
		
		public function get width():int {
			if (!mError)
				return mRaster.width;
			return 0;
		}
		
		public function get height():int {
			if (!mError)
				return mRaster.height;
			return 0;
		}
		
		/** Обновить таймер ожидания */
		public function touch():void {
			mTimestamp = getTimer();
		}
		
		/** Флаг ошибочного или давно не использованного изображения */
		public function isUseless():Boolean {
			return mError || ((getTimer() - mTimestamp) > TIMEOUT);
		}
		
		public function toString():String {
			return printClass(this, "path", "error", "width", "height");
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var mTimestamp:int; // время последнего обращения к изображению
		private var mPath:String;
		private var mRaster:BitmapData;
		private var mError:Boolean;
		
		private static const RECT:Rectangle = new Rectangle();
		private static const TIMEOUT:int = 60000; // время жизни успешно загруженных изображений
		
	}
}
