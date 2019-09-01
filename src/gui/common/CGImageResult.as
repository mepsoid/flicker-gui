package ui.common {
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	import services.printClass;
	
	/**
	 * Данные о загруженном изображении
	 * 
	 * @version  1.0.6
	 * @author   meps
	 */
	public class CGImageResult {
		
		public function CGImageResult(path:String, data:DisplayObject = null) {
			m_timestamp = getTimer();
			m_path = path;
			if (data is BitmapData) {
				// исходная графика растр
				m_raster = Bitmap(data).bitmapData;
				m_error = false;
			} else if (data) {
				// исходная графика рендерится в битмап
				m_raster = new BitmapData(data.width, data.height, true, 0x00000000);
				m_raster.draw(data, null, null, null, null, true);
				m_error = false;
			} else {
				// ошибка при загрузке
				m_raster = null;
				m_error = true;
			}
		}
		
		/** Путь к изображению */
		public function get path():String {
			return m_path;
		}
		
		/** Растровые данные изображения */
		public function get raster():BitmapData {
			return m_raster;
		}
		
		/** Создать графику на основе растра */
		public function create():Bitmap {
			if (m_raster) {
				var bitmap:Bitmap = new Bitmap(m_raster);
				bitmap.smoothing = true;
				return bitmap;
			}
			// пустой результат; никем не должен запрашиваться
			return null;
		}
		
		/** Флаг успешной загрузки изображения */
		public function get error():Boolean {
			return m_error;
		}
		
		public function get width():int {
			if (!m_error)
				return m_raster.width;
			return 0;
		}
		
		public function get height():int {
			if (!m_error)
				return m_raster.height;
			return 0;
		}
		
		/** Обновить таймер ожидания */
		public function touch():void {
			m_timestamp = getTimer();
		}
		
		/** Флаг ошибочного или давно не использованного изображения */
		public function isUseless():Boolean {
			return m_error || ((getTimer() - m_timestamp) > TIMEOUT);
		}
		
		public function toString():String {
			return printClass(this, "path", "error", "width", "height");
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_timestamp:int; // время последнего обращения к изображению
		private var m_path:String;
		private var m_raster:BitmapData;
		private var m_error:Boolean;
		
		private static const RECT:Rectangle = new Rectangle();
		private static const TIMEOUT:int = 60000; // время жизни успешно загруженных изображений
		
	}
}