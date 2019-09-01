package ui.common {
	
	import flash.utils.Dictionary;
	
	/**
	 * Обертка визуального класса для создания непосредственных экземпляров графики на основе ресурсов скинов
	 * 
	 * @version  1.0.3
	 * @author   meps
	 */
	public class CGSkinHelper implements IGSkinnable {
		
		/** Подписать обработчик на обновление клипа с заданным идентификатором и сразу же вернуть экземпляр клипа */
		public static function create(resourceId:String, listener:Function = null):* {
			var helper:CGSkinHelper = new CGSkinHelper(resourceId, listener, new TSkinHelperLock());
			return helper.m_data;
		}
		
		/** Корректно завершить работу обработчика */
		public static function remove(resourceId:String, listener:Function):void {
			for (var item:Object in m_pool) {
				var helper:CGSkinHelper = CGSkinHelper(item);
				if (helper.m_id == resourceId && helper.m_listener === listener) {
					helper.destroy();
					return;
				}
			}
		}
		
		/** @private */
		public function CGSkinHelper(resourceId:String, listener:Function, lock:TSkinHelperLock) {
			if (!lock)
				throw new Error("Use CGSkinHelper.create for instantiation!");
			m_id = resourceId;
			m_listener = listener;
			CGSkin.instance.connect(m_id, this); // получить текущий ресурс
			if (m_listener == null)
				// если нет обработчика, то сразу же отписаться от колбеков на обновление скинов
				CGSkin.instance.disconnect(m_id, this);
			else
				// если есть обработчик, сохранить указатель на обертку для возможности ее уничтожения и отписки от обновления скинов
				m_pool[this] = true;
		}
		
		/** Обработчик обновления скина; вызывается синхронно сразу после регистрации */
		public function skinUpdate(resourceId:String, data:*):void {
			if (resourceId != m_id)
				return;
			if (data === m_data)
				// крайне маловероятно, что в обновлении будет участвовать тот же экземпляр ресурса
				return;
			m_data = data;
			// оповестить подписчик об обновлении ресурса
			if (m_listener != null)
				m_listener(m_data);
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Удалить экземпляр обертки */
		private function destroy():void {
			delete m_pool[this];
			CGSkin.instance.disconnect(m_id, this);
			m_data = null;
			m_listener = null;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_id:String;
		private var m_data:*; // текущий хранящийся ресурс
		private var m_listener:Function;
		
		private static const m_pool:Dictionary = new Dictionary(); // список всех созданных обработчиков
		
	}

}

internal class TSkinHelperLock { }
