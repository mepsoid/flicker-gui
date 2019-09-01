package ui.common {
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import services.printClass;
	
	/**
	 * Данные о загруженном изображении
	 * 
	 * @version  1.0.3
	 * @author   meps
	 */
	internal class CGImageResult {
		
		public function CGImageResult(path:String, data:DisplayObject = null) {
			m_path = path;
			if (data) {
				// успешная загрузка
				m_image = data;
				/*
				m_unscaled = new BitmapData(m_image.width, m_image.height, true, 0);
				m_unscaled.draw(m_image, null, null, null, null, true);
				*/
				m_error = false;
			} else {
				// ошибка при загрузке
				m_image = null;
				m_error = true;
			}
		}
		
		/** Путь к изображению */
		public function get path():String {
			return m_path;
		}
		
		/** Экземпляр изображения */
		public function get data():DisplayObject {
			return m_image;
		}
		
		/** Флаг успешной загрузки изображения */
		public function get error():Boolean {
			return m_error;
		}
		
		public function get width():int {
			if (!m_error)
				return m_image.width;
			return 0;
		}
		
		public function get height():int {
			if (!m_error)
				return m_image.height;
			return 0;
		}
		
		public function toString():String {
			return printClass(this, "path", "error", "width", "height");
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Функция клонирования для сохранения исходного объекта */
		internal function clone():CGImageResult {
			if (m_error)
				// для незагруженных изображений нет смысла создавать копии, они и так пустые 
				return this;
			// исходная графика клонируется в битмап
			var raster:BitmapData = new BitmapData(m_image.width, m_image.height, true, 0x00000000);
			raster.draw(m_image, null, null, null, null, true);
			var bitmap:Bitmap = new Bitmap(raster);
			bitmap.smoothing = true;
			var result:CGImageResult = new CGImageResult(m_path, bitmap);
			return result;
		}
		
		/** Функция отрисовки загруженного изображения по матрице */
		/*
		public function draw(matrix:Matrix, bitmap:Bitmap):void {
			if (m_error)
				// нечего отрисовывать
				return;
			var data:BitmapData = bitmap.bitmapData;
			if (data == null) {
				data = new BitmapData(m_image.width, m_image.height, true, 0x00000000);
				data.lock();
				bitmap.bitmapData = data;
			} else if (data.width != m_image.width || data.height != m_image.height) {
				data = new BitmapData(m_image.width, m_image.height, true, 0x00000000);
				data.lock();
				bitmap.bitmapData = data;
			} else {
				data.lock();
				RECT.width = m_image.width;
				RECT.height = m_image.height;
				data.fillRect(RECT, 0x00000000);
			}
			//var sh:Shape = new Shape();
			//sh.graphics.beginBitmapFill(m_unscaled,matrix,false,true);
			//sh.graphics.lineStyle(0,0,0); // no lines border this shape
			//sh.graphics.drawRect(0,0,m_image.width,m_image.height);
			//sh.graphics.endFill();
			//data.draw(sh, null, null, null, null, true); // or with smoothing on
			//data.draw(m_image, matrix, null, null, null, true);
			data.unlock();
		}
		*/
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_path:String;
		private var m_image:DisplayObject;
		//private var m_unscaled:BitmapData;
		private var m_error:Boolean;
		
		private static const RECT:Rectangle = new Rectangle();
		
	}
}