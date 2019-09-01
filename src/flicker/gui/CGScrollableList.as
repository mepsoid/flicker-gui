package flicker.gui {
	
	import flash.display.MovieClip;
	
	/**
	 * Список скроллируемых элементов
	 *
	 * @version  1.0.8
	 * @author   meps
	 */
	public class CGScrollableList extends CGResizable {
		
		public function CGScrollableList(renderer:Class = null, src:* = null, name:String = null) {
			mRenderer = renderer ? renderer : CGScrollableItem;
			mPosition = 0.0;
			mSlider = 1.0;
			mGrid = 1;
			mListData = new Vector.<Object>();
			mListRenderer = new Vector.<CGScrollableItem>();
			super(src, name);
			doRedraw();
		}
		
		/** Обновить данные в списке */
		public function update(data:Vector.<Object> = null):void {
			if (data && data.length)
				mListData = data.concat();
			else
				mListData.length = 0;
			onDataUpdate(mListData);
			doRedraw();
		}
		
		/** Текущая позиция списка */
		public function get position():Number {
			return mPosition;
		}
		
		public function set position(val:Number):void {
			if (val < 0.0)
				val = 0.0;
			else if (val > 1.0)
				val = 1.0;
			if (val == mPosition)
				return;
			mPosition = val;
			doRedraw();
		}
		
		/** Текущее соотношение отображаемой области списка */
		public function get slider():Number {
			return mSlider;
		}
		
		/** Дискретность позиционирования в элементах при прокрутке */
		public function get grid():int {
			return mGrid;
		}
		
		public function set grid(val:int):void {
			if (val < 1)
				val = 1;
			if (val == mGrid)
				return;
			mGrid = val;
			doRedraw();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function onDestroy():void {
			mListData = null;
			if (mListRenderer)
				for each (var item:CGScrollableItem in mListRenderer)
					item.destroy();
			mListRenderer = null;
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
			return new mRenderer(this, name);
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
			var index:int = mListRenderer.indexOf(item);
			if (index < 0)
				return null;
			var len:int = mListData.length;
			var lenGrid:int = int((len - 1) / mGrid + 1) * mGrid;
			index += int(mPosition * lenGrid / mGrid) * mGrid;
			if (index >= len)
				return null;
			return mListData[index];
		}
		
		/** Получить индекс в списке данных по экземпляру */
		protected function dataToIndex(data:*):int {
			return mListData.indexOf(data);
		}
		
		/** Перерисовка всего списка элементов */
		protected function doRedraw():void {
			var index:int = 0;
			var len:int = mListData.length; // собственная длина данных
			var lenGrid:int = int((len - 1) / mGrid + 1) * mGrid; // увеличенная по текущей сетке длина
			var pos:int = int(mPosition * lenGrid / mGrid) * mGrid;
			var offset:int = 1000 * (mPosition * lenGrid / mGrid - int(mPosition * lenGrid / mGrid)); // плавная прокрутка в grid раз медленнее
			size = offset; // установить промежуточное положение списка
			while (true) {
				var item:CGScrollableItem = getRenderer(index);
				if (!item)
					break;
				if (pos < len) {
					var data:* = mListData[pos];
					onRendererUpdate(item, data);
				} else {
					onRendererClear(item);
				}
				++index;
				++pos;
			}
			if (len == 0 || index == 0) {
				mSlider = 1.0;
			} else {
				mSlider = (offset ? index - mGrid : index) / lenGrid;
				if (mSlider > 1.0)
					mSlider = 1.0;
			}
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Рендерер по индексу */
		private function getRenderer(index:int):CGScrollableItem {
			var name:String, mc:MovieClip;
			var len:int = mListRenderer.length;
			if (index < len) {
				name = ITEM_PREFIX + index.toString();
				mc = objectFind(name) as MovieClip;
				if (!mc)
					return null;
				return mListRenderer[index];
			}
			do {
				name = ITEM_PREFIX + len.toString();
				mc = objectFind(name) as MovieClip;
				if (!mc)
					return null;
				var item:CGScrollableItem = onRendererCreate(name);
				mListRenderer[len] = item;
				++len;
			} while (len < index);
			return item;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Класс рендерера элемента списка */
		private var mRenderer:Class;
		
		/** Позиция списка */
		private var mPosition:Number;
		
		/** Соотношение отображаемой области */
		private var mSlider:Number;
		
		/** Шаг в количестве отображаемых элементов для прокрутки списков с несколькими колонками */
		private var mGrid:int;
		
		/** Список отображаемых данных */
		private var mListData:Vector.<Object>;
		
		/** Список уже созданных рендереров */
		private var mListRenderer:Vector.<CGScrollableItem>;
		
		private static const ITEM_PREFIX:String = ".item_";
		
	}

}
