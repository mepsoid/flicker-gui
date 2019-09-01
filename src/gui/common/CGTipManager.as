package framework.gui {
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	/**
	 * Менеджер тултипов
	 * 
	 * @version  1.0.4
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
			return mContainer;
		}
		
		public function set container(val:DisplayObjectContainer):void {
			mContainer = val;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Включение отображения тултипа */ 
		internal function tipAdd(tip:CGTip):void {
			var coords:Point, mcOld:MovieClip;
			var mcNew:MovieClip = tip.clip;
			// проверить на совпадение с уже отображаемым клипом
			if (mTip) {
				mcOld = mPool[mTip];
				if (mcOld === mcNew)
					// клипы полностью совпали, игнорировать обновление
					return;
				// удалить старый клип, если он был
				if (mContainer)
					mContainer.removeChild(mcOld);
			}
			// обновить кеш клипов тултипов
			mTip = tip;
			if (mcNew) {
				// новый клип добавить в кеш и выровнять по рабочей области
				mPool[mTip] = mcNew;
				var parent:DisplayObjectContainer = mcNew.parent;
				if (parent) {
					// тултип вписан в элемент
					coords = new Point(mcNew.x, mcNew.y);
					coords = parent.localToGlobal(coords);
				} else {
					// тултип создан из ресурса
					coords = new Point();
				}
				coords = mContainer.globalToLocal(coords);
				mcNew.x = coords.x;
				mcNew.y = coords.y;
			} else {
				mcNew = mPool[mTip];
			}
			if (!mcNew)
				// нет клипа у тултипа
				return;
			mcNew.mouseEnabled = false;
			mcNew.mouseChildren = false;
			mContainer.addChild(mcNew);
			mcNew.visible = true;
		}
		
		/** Удаление тултипа из области отображения */
		internal function tipRemove(tip:CGTip):void {
			if (mTip !== tip)
				// попытка удалить чужой клип
				return;
			var mc:MovieClip = mTip.clip;
			if (!mc)
				mc = mPool[mTip];
			if (mContainer && mc)
				mContainer.removeChild(mc);
			mTip = null;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var mContainer:DisplayObjectContainer;
		private var mTip:CGTip; // текущий отображаемый тултип
		private var mPool:Dictionary = new Dictionary(); // пул клипов тултипов
		
		private static var m_instance:CGTipManager;
		
	}

}

internal class TipManagerLock {
}
