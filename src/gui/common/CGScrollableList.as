package ui.common {
	
	import flash.display.MovieClip;
	import services.printClass;
	
	/**
	 * Список скроллируемых элементов
	 * 
	 * @version  1.0.7
	 * @author   meps
	 */
	public class CGScrollableList extends CGResizable {
		
		public function CGScrollableList(renderer:Class = null, src:* = null, name:String = null) {
			m_renderer = renderer ? renderer : CGScrollableItem;
			m_position = 0.0;
			m_slider = 1.0;
			m_grid = 1;
			m_listData = new Vector.<Object>();
			m_listRenderer = new Vector.<CGScrollableItem>();
			super(src, name);
			doRedraw();
		}
		
		/** Обновить данные в списке */
		public function update(data:Vector.<Object> = null):void {
			if (data && data.length)
				m_listData = data.concat();
			else
				m_listData.length = 0;
			onDataUpdate(m_listData);
			doRedraw();
		}
		
		/** Текущая позиция списка */
		public function get position():Number {
			return m_position;
		}
		
		public function set position(val:Number):void {
			if (val < 0.0)
				val = 0.0;
			else if (val > 1.0)
				val = 1.0;
			if (val == m_position)
				return;
			m_position = val;
			doRedraw();
		}
		
		/** Текущее соотношение отображаемой области списка */
		public function get slider():Number {
			return m_slider;
		}
		
		/** Дискретность позиционирования в элементах при прокрутке */
		public function get grid():int {
			return m_grid;
		}
		
		public function set grid(val:int):void {
			if (val < 1)
				val = 1;
			if (val == m_grid)
				return;
			m_grid = val;
			doRedraw();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function onDestroy():void {
			m_listData = null;
			if (m_listRenderer)
				for each (var item:CGScrollableItem in m_listRenderer)
					item.destroy();
			m_listRenderer = null;
			super.onDestroy();
		}
		
		override protected function onClipParent():void {
			super.onClipParent();
			doRedraw();
		}
		
		/** Обновление данных списка */
		protected function onDataUpdate(list:Vector.<Object>):void {
		}
		
		/** Создание нового рендерера для связывания со слушателями и инициализации */
		protected function onRendererCreate(name:String):CGScrollableItem {
			return new m_renderer(this, name);
		}
		
		/** Обновление содержимого рендерера при перерисовке списка */
		protected function onRendererUpdate(item:CGScrollableItem, data:*):void {
			item.update(data);
		}
		
		/** Скрывание рендерера при его фактическом отсутствии в списке */
		protected function onRendererClear(item:CGScrollableItem):void {
			item.clear();
		}
		
		/** Получить данные связанные с рендерером */
		protected function rendererToData(item:*):* {
			var index:int = m_listRenderer.indexOf(item);
			if (index < 0)
				return null;
			var len:int = m_listData.length;
			var lenGrid:int = int((len - 1) / m_grid + 1) * m_grid;
			index += int(m_position * lenGrid / m_grid) * m_grid;
			if (index >= len)
				return null;
			return m_listData[index];
		}
		
		/** Получить индекс в списке данных по экземпляру */
		protected function dataToIndex(data:*):int {
			return m_listData.indexOf(data);
		}
		
		/** Перерисовка всего списка элементов */
		protected function doRedraw():void {
			var index:int = 0;
			var len:int = m_listData.length; // собственная длина данных
			var lenGrid:int = int((len - 1) / m_grid + 1) * m_grid; // увеличенная по текущей сетке длина
			var pos:int = int(m_position * lenGrid / m_grid) * m_grid;
			var offset:int = 1000 * (m_position * lenGrid / m_grid - int(m_position * lenGrid / m_grid)); // плавная прокрутка в grid раз медленнее
			size = offset; // установить промежуточное положение списка
			while (true) {
				var item:CGScrollableItem = getRenderer(index);
				if (!item)
					break;
				if (pos < len) {
					var data:* = m_listData[pos];
					onRendererUpdate(item, data);
				} else {
					onRendererClear(item);
				}
				++index;
				++pos;
			}
			if (len == 0 || index == 0) {
				m_slider = 1.0;
			} else {
				m_slider = (offset ? index - m_grid : index) / lenGrid;
				if (m_slider > 1.0)
					m_slider = 1.0;
			}
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Рендерер по индексу */
		private function getRenderer(index:int):CGScrollableItem {
			var name:String, mc:MovieClip;
			var len:int = m_listRenderer.length;
			if (index < len) {
				name = ITEM_PREFIX + index.toString();
				mc = objectFind(name) as MovieClip;
				if (!mc)
					return null;
				return m_listRenderer[index];
			}
			do {
				name = ITEM_PREFIX + len.toString();
				mc = objectFind(name) as MovieClip;
				if (!mc)
					return null;
				var item:CGScrollableItem = onRendererCreate(name);
				m_listRenderer[len] = item;
				++len;
			} while (len < index);
			return item;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Класс рендерера элемента списка */
		private var m_renderer:Class;
		
		/** Позиция списка */
		private var m_position:Number;
		
		/** Соотношение отображаемой области */
		private var m_slider:Number;
		
		/** Шаг в количестве отображаемых элементов для прокрутки списков с несколькими колонками */
		private var m_grid:int;
		
		/** Список отображаемых данных */
		private var m_listData:Vector.<Object>;
		
		/** Список уже созданных рендереров */
		private var m_listRenderer:Vector.<CGScrollableItem>;
		
		private static const ITEM_PREFIX:String = ".item_";
		
	}

}