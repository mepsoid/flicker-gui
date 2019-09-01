package ui.common {
	
	/**
	 * Общие настройки компонентов интерфейса
	 * 
	 * @version  1.0.1
	 * @author   meps
	 */
	public class CGSetup {
		
		/** Поддерживаемая логическая частота кадров при анимациях перехода */
		public static function get fps():Number {
			return m_fps * 1000;
		}
		
		public static function set fps(val:Number):void {
			if (val > 0)
				m_fps = val / 1000;
		}
		
		public static function get fpsMultiplier():Number {
			return m_fps;
		}
		
		public function CGSetup() {
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Глобальная частота кадров */
		private static var m_fps:Number = 60.0 / 1000;
		
	}

}