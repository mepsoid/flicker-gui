package ui.common {
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	/**
	 * Менеджер тултипов
	 * 
	 * @version  1.0.3
	 * @author   meps
	 */
	public class CGTipManager {
		
		/** Экземпляр менеджера тултипов */
		public static function get instance():CGTipManager {
			if (!m_instance)
				m_instance = new CGTipManager(new TipManagerLock());
			return m_instance;
		}
		
		/** @private */
		public function CGTipManager(lock:TipManagerLock) {
			if (!lock)
				throw new Error("Use CGTipManager.instance for access!");
		}
		
		/** Контейнер тултипов */
		public function get container():DisplayObjectContainer {
			return m_container;
		}
		
		public function set container(val:DisplayObjectContainer):void {
			m_container = val;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Включение отображения тултипа */ 
		internal function tipAdd(tip:CGTip):void {
			var coords:Point, mcOld:MovieClip;
			var mcNew:MovieClip = tip.clip;
			// проверить на совпадение с уже отображаемым клипом
			if (m_tip) {
				mcOld = m_cache[m_tip];
				if (mcOld === mcNew)
					// клипы полностью совпали, игнорировать обновление
					return;
				// удалить старый клип, если он был
				if (m_container)
					m_container.removeChild(mcOld);
			}
			// обновить кеш клипов тултипов
			m_tip = tip;
			if (mcNew) {
				// новый клип добавить в кеш и выровнять по рабочей области
				m_cache[m_tip] = mcNew;
				var parent:DisplayObjectContainer = mcNew.parent;
				if (parent) {
					// тултип вписан в элемент
					coords = new Point(mcNew.x, mcNew.y);
					coords = parent.localToGlobal(coords);
				} else {
					// тултип создан из ресурса
					coords = new Point();
				}
				coords = m_container.globalToLocal(coords);
				mcNew.x = coords.x;
				mcNew.y = coords.y;
			} else {
				mcNew = m_cache[m_tip];
			}
			if (!mcNew)
				// нет клипа у тултипа
				return;
			mcNew.mouseEnabled = false;
			mcNew.mouseChildren = false;
			m_container.addChild(mcNew);
			mcNew.visible = true;
		}
		
		/** Удаление тултипа из области отображения */
		internal function tipRemove(tip:CGTip):void {
			if (m_tip !== tip)
				// попытка удалить чужой клип
				return;
			var mc:MovieClip = m_tip.clip;
			if (!mc)
				mc = m_cache[m_tip];
			if (m_container && mc)
				m_container.removeChild(mc);
			m_tip = null;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_container:DisplayObjectContainer;
		private var m_tip:CGTip; // текущий отображаемый тултип
		private var m_cache:Dictionary = new Dictionary(); // кеш клипов тултипов
		
		private static var m_instance:CGTipManager;
		
	}

}

internal class TipManagerLock {
}
