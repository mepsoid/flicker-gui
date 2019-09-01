package framework.gui {
	
	/**
	 * Общие настройки компонентов интерфейса
	 * 
	 * @version  1.0.2
	 * @author   meps
	 */
	public class CGSetup {
		
		/** Поддерживаемая логическая частота кадров при анимациях перехода */
		public static function get fps():Number {
			return mFps * 1000;
		}
		
		public static function set fps(val:Number):void {
			if (val > 0)
				mFps = val / 1000;
		}
		
		public static function get fpsMultiplier():Number {
			return mFps;
		}
		
		public function CGSetup() {
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Глобальная частота кадров */
		private static var mFps:Number = 30.0 / 1000;
		
	}

}
