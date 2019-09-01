package ui.common {
	
	/**
	 * Контроллер скроллируемого списка
	 * 
	 * @version  1.0.11
	 * @author   meps
	 */
	public class CGScrollable extends CGProto {
		
		public function CGScrollable(prefix:String, listRenderer:Class = null, itemRenderer:Class = null, src:* = null, name:String = null) {
			m_enable = false;
			super(src, name);
			// задать шаг по умолчанию
			m_gridConst = prefix + STEP_SUFFIX;
			//constDefault(m_gridConst, "1");
			updateGridConst();
			m_list = listRenderer ? new listRenderer(this, prefix + LIST_SUFFIX) : new CGScrollableList(itemRenderer, this, prefix + LIST_SUFFIX);
			m_list.grid = m_grid;
			m_scroll = new CGScrollSeparate(this, prefix);
			m_scroll.eventSign(true, CGScrollSeparate.POSITION, onScrollPosition);
		}
		
		/** Указатель на список */
		public function get list():CGScrollableList {
			return m_list;
		}
		
		/** Указатель на прокрутку */
		public function get scroll():CGScrollSeparate {
			return m_scroll;
		}
		
		/** Обновить значения скроллируемого списка */
		public function update(data:* = null):void {
			var list:Vector.<Object> = null;
			var len:int = 0, index:int;
			if (data is Array) {
				var arr:Array = data as Array;
				len = arr.length;
				list = new Vector.<Object>();
				for (index = 0; index < len; ++index)
					list[index] = arr[index];
			} else if (data is Vector.<*>) {
				var vec:Vector.<*> = data as Vector.<*>;
				len = vec.length;
				list = new Vector.<Object>();
				for (index = 0; index < len; ++index)
					list[index] = vec[index];
			}
			m_enable = len > 0;
			doState();
			m_list.update(list);
			// обновить скроллер
			if (m_enable) {
				var lenGrid:int = int((len - 1) / m_grid + 1) * m_grid;
				m_scroll.enable = true;
				m_scroll.step = m_grid / lenGrid;
				m_scroll.size = m_list.slider;
			} else {
				m_scroll.enable = false;
				m_scroll.position = 0.0;
			}
		}
		
		/** Подписка на события вложенного списка */
		public function listEventSign(sign:Boolean, type:String, listener:Function):void {
			if (m_list)
				m_list.eventSign(sign, type, listener);
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function onDestroy():void {
			m_list.destroy();
			m_list = null;
			m_scroll.destroy();
			m_scroll = null;
			super.onDestroy();
		}
		
		override protected function doStateValue():String {
			return m_enable ? COMMON_STATE : EMPTY_STATE;
		}
		
		override protected function onClipProcess():void {
			super.onClipProcess();
			updateGridConst();
			if (m_list)
				m_list.grid = m_grid;
		}
		
		override protected function onClipParent():void {
			super.onClipParent();
			m_scroll.size = m_list.slider;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private function onScrollPosition(event:CGEvent):void {
			m_list.position = m_scroll.position;
		}
		
		private function updateGridConst():void {
			m_grid = parseInt(constGet(m_gridConst));
			if (m_grid < 1)
				m_grid = 1;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_enable:Boolean;
		private var m_list:CGScrollableList;
		private var m_scroll:CGScrollSeparate;
		private var m_grid:int;
		private var m_gridConst:String;
		
		private static const LIST_SUFFIX:String = "_wheel";
		private static const STEP_SUFFIX:String = "_step";
		private static const COMMON_STATE:String = "common";
		private static const EMPTY_STATE:String = "empty";
		
	}

}