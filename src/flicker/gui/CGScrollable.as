package flicker.gui {
	
	/**
	 * Контроллер скроллируемого списка
	 * 
	 * @version  1.0.12
	 * @author   meps
	 */
	public class CGScrollable extends CGProto {
		
		public function CGScrollable(prefix:String, listRenderer:Class = null, itemRenderer:Class = null, src:* = null, name:String = null) {
			mEnable = false;
			super(src, name);
			// задать шаг по умолчанию
			mGridConst = prefix + STEP_SUFFIX;
			//constDefault(m_gridConst, "1");
			updateGridConst();
			mList = listRenderer ? new listRenderer(this, prefix + LIST_SUFFIX) : new CGScrollableList(itemRenderer, this, prefix + LIST_SUFFIX);
			mList.grid = mGrid;
			mScroll = new CGScrollSeparate(this, prefix);
			mScroll.eventSign(true, CGScrollSeparate.POSITION, onScrollPosition);
		}
		
		/** Указатель на список */
		public function get list():CGScrollableList {
			return mList;
		}
		
		/** Указатель на прокрутку */
		public function get scroll():CGScrollSeparate {
			return mScroll;
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
			mEnable = len > 0;
			doState();
			mList.update(list);
			// обновить скроллер
			if (mEnable) {
				var lenGrid:int = int((len - 1) / mGrid + 1) * mGrid;
				mScroll.enable = true;
				mScroll.step = mGrid / lenGrid;
				mScroll.size = mList.slider;
			} else {
				mScroll.enable = false;
				mScroll.position = 0.0;
			}
		}
		
		/** Подписка на события вложенного списка */
		public function listEventSign(sign:Boolean, type:String, listener:Function):void {
			if (mList)
				mList.eventSign(sign, type, listener);
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function onDestroy():void {
			mList.destroy();
			mList = null;
			mScroll.destroy();
			mScroll = null;
			super.onDestroy();
		}
		
		override protected function doStateValue():String {
			return mEnable ? COMMON_STATE : EMPTY_STATE;
		}
		
		override protected function onClipProcess():void {
			super.onClipProcess();
			updateGridConst();
			if (mList)
				mList.grid = mGrid;
		}
		
		override protected function onClipParent():void {
			super.onClipParent();
			mScroll.size = mList.slider;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private function onScrollPosition(event:CGEvent):void {
			mList.position = mScroll.position;
		}
		
		private function updateGridConst():void {
			mGrid = parseInt(constGet(mGridConst));
			if (mGrid < 1)
				mGrid = 1;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var mEnable:Boolean;
		private var mList:CGScrollableList;
		private var mScroll:CGScrollSeparate;
		private var mGrid:int;
		private var mGridConst:String;
		
		private static const LIST_SUFFIX:String = "_wheel";
		private static const STEP_SUFFIX:String = "_step";
		private static const COMMON_STATE:String = "common";
		private static const EMPTY_STATE:String = "empty";
		
	}

}
