package awaybuilder.desktop.view.mediators
{

	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.InvokeEvent;
	import flash.events.KeyboardEvent;
	import flash.filesystem.File;
	import flash.system.Capabilities;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	
	import mx.core.DragSource;
	import mx.core.IIMESupport;
	import mx.core.UIComponent;
	import mx.events.DragEvent;
	import mx.events.FlexNativeMenuEvent;
	import mx.events.MenuEvent;
	import mx.managers.DragManager;
	import mx.managers.IFocusManagerComponent;
	
	import awaybuilder.controller.clipboard.events.ClipboardEvent;
	import awaybuilder.controller.document.events.ImportTextureEvent;
	import awaybuilder.controller.events.DocumentEvent;
	import awaybuilder.controller.events.DocumentModelEvent;
	import awaybuilder.controller.events.DocumentRequestEvent;
	import awaybuilder.controller.events.ErrorLogEvent;
	import awaybuilder.controller.events.SaveDocumentEvent;
	import awaybuilder.controller.events.TextureSizeErrorsEvent;
	import awaybuilder.controller.history.UndoRedoEvent;
	import awaybuilder.controller.scene.events.SceneEvent;
	import awaybuilder.desktop.controller.events.OpenFromInvokeEvent;
	import awaybuilder.desktop.utils.ModalityManager;
	import awaybuilder.model.DocumentModel;
	import awaybuilder.model.UndoRedoModel;
	import awaybuilder.model.vo.scene.AssetVO;
	import awaybuilder.model.vo.scene.ObjectVO;
	import awaybuilder.utils.enumerators.EMenuItem;
	import awaybuilder.view.components.editors.events.PropertyEditorEvent;
	import awaybuilder.view.mediators.BaseApplicationMediator;

	public class LibraryApplicationMediator extends BaseApplicationMediator
	{
		[Inject]
		public var app:AwayBuilderLibMain;
		
		[Inject]
		public var documentModel:DocumentModel;
		
		[Inject]
		public var undoRedoModel:UndoRedoModel;
		
		private var _isWin:Boolean; 
		private var _isMac:Boolean;
		
		private var _menuCache:Dictionary;
		
		override public function onRegister():void
		{	
			_menuCache = new Dictionary();
			
			app.addEventListener(AwayBuilderLibMain.DISPOSE, dispose);
			
			// attach custom menu system generated 
			// by Moonshine
			app.attachMenu();

			app.menu.addEventListener(MenuEvent.ITEM_CLICK, menuLib_itemClickHandler, false, 0, true);
			app.eventDispatcher.addEventListener("awayBuilderMenuEvent", onMenuLib_itemClickHandler, false, 0, true);
			
			addContextListener( DocumentModelEvent.DOCUMENT_NAME_CHANGED, eventDispatcher_documentNameChangedHandler);
			addContextListener( DocumentModelEvent.DOCUMENT_EDITED, eventDispatcher_documentEditedHandler);
			
            addContextListener( SceneEvent.SELECT, context_itemSelectHandler);
			addContextListener( SceneEvent.SWITCH_CAMERA_TO_FREE, eventDispatcher_switchToFreeCameraHandler);
			addContextListener( SceneEvent.SWITCH_CAMERA_TO_TARGET, eventDispatcher_switchToTargetCameraHandler);
			addContextListener( SceneEvent.SWITCH_TRANSFORM_TRANSLATE, eventDispatcher_switchTranslateHandler);
			addContextListener( SceneEvent.SWITCH_TRANSFORM_ROTATE, eventDispatcher_switchRotateHandler);
			addContextListener( SceneEvent.SWITCH_TRANSFORM_SCALE, eventDispatcher_switchScaleCameraHandler);

			addContextListener( ClipboardEvent.CLIPBOARD_COPY, context_copyHandler);
            addContextListener( UndoRedoEvent.UNDO_LIST_CHANGE, context_undoListChangeHandler);
            addContextListener( ErrorLogEvent.LOG_ENTRY_MADE, eventDispatcher_errorLogHandler);
          
			addViewListener( Event.CLOSING, awaybuilder_closingHandler );
			addViewListener( DragEvent.DRAG_ENTER, awaybuilder_dragEnterHandler );
			addViewListener( DragEvent.DRAG_DROP, awaybuilder_dragDropHandler );
			addViewListener( InvokeEvent.INVOKE, invokeHandler );
			
			CONFIG::MOONSHINE
				{
					addViewListener( PropertyEditorEvent.REPLACE_AND_LOAD_TEXTURE_FROM_MOONSHINE, view_replaceTextureHandlerFromMoonshine );
					addViewListener( PropertyEditorEvent.SAVE_FROM_MOONSHINE, event_saveRequestFromMoonshine );
				}

			this.eventMap.mapListener(app.stage, KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
			//app.stage.addEventListener(FocusEvent.FOCUS_IN, focusInHandler );
			
			//fix for linux window size bug
			/*this.app.nativeWindow.height++;
			this.app.nativeWindow.height--;*/
			
			getItemByValue( EMenuItem.UNDO ).enabled = undoRedoModel.canUndo;
			getItemByValue( EMenuItem.REDO ).enabled = undoRedoModel.canRedo;
			getItemByValue( EMenuItem.FOCUS ).enabled = false;
			getItemByValue( EMenuItem.DELETE ).enabled = false;
			getItemByValue( EMenuItem.CUT ).enabled = false;
			getItemByValue( EMenuItem.COPY ).enabled = false;
			getItemByValue( EMenuItem.PASTE ).enabled = false;
			
			_isWin = (Capabilities.os.indexOf("Windows") >= 0); 
			_isMac = (Capabilities.os.indexOf("Mac OS") >= 0); 
			
			if( _isMac && !CONFIG::MOONSHINE)
			{
				getItemByValue( EMenuItem.EXIT ).keyEquivalent = "q";
				getItemByValue( EMenuItem.EXIT ).keyEquivalentModifiers = [Keyboard.COMMAND];
			}
		}

		private function focusInHandler(event:FocusEvent):void
		{
			const focus:IFocusManagerComponent = app.focusManager.getFocus();
			if( focus is IIMESupport )
			{
				getItemByValue( EMenuItem.CUT ).keyEquivalentModifiers = [Keyboard.ALTERNATE, app.getCommandKey()];
				getItemByValue( EMenuItem.COPY ).keyEquivalentModifiers = [Keyboard.ALTERNATE, app.getCommandKey()];
				getItemByValue( EMenuItem.PASTE ).keyEquivalentModifiers = [Keyboard.ALTERNATE, app.getCommandKey()];
			}
			else
			{
				getItemByValue( EMenuItem.CUT ).keyEquivalentModifiers = [app.getCommandKey()];
				getItemByValue( EMenuItem.COPY ).keyEquivalentModifiers = [app.getCommandKey()];
				getItemByValue( EMenuItem.PASTE ).keyEquivalentModifiers = [app.getCommandKey()];
			}
		}
		
		private function getItemByValue( value:String ):Object
		{
			if( _menuCache[value] ) return _menuCache[value];
			_menuCache[value] = findItem( value, app.menu.menu.items );
			return _menuCache[value];
		}
		private function findItem( value:String, items:* ):Object
		{
			for each( var item:Object in items )
			{
				var menuItem:Object;
				if( item.label == value ) return item;
				if( item.submenu && item.submenu.items.length > 0 )
				{
					menuItem = findItem( value, item.submenu.items );
					if( menuItem ) return menuItem;
				}
			}
			return null;
		}
		private function invokeHandler(event:InvokeEvent):void
		{
			if(event.arguments.length == 1)
			{
				const extensions:Vector.<String> = new <String>["awd","AWD"];
				var filePath:String = event.arguments[0];
				var file:File = new File(filePath);
				if(file.exists && extensions.indexOf(file.extension) >= 0)
				{
					dispatch(new OpenFromInvokeEvent(OpenFromInvokeEvent.OPEN_FROM_INVOKE, file));
				}
			}
		}
		
        private function context_undoListChangeHandler(event:UndoRedoEvent):void
        {
			getItemByValue( EMenuItem.UNDO ).enabled = undoRedoModel.canUndo;
			getItemByValue( EMenuItem.REDO ).enabled = undoRedoModel.canRedo;
        }
	
		private function eventDispatcher_errorLogHandler(event:ErrorLogEvent):void {
			this.dispatch(new TextureSizeErrorsEvent(TextureSizeErrorsEvent.SHOW_TEXTURE_SIZE_ERRORS));
		}

		private function updatePageTitle():void
		{
			/*var newTitle:String = "Away Builder - " + this.documentModel.name;
			if(this.documentModel.edited)
			{
				newTitle += " *";
			}*/
			
			app.coreEditor.editToolbar.documentName = this.documentModel.name;
		}
		
		private function eventDispatcher_documentEditedHandler(event:DocumentModelEvent):void
		{
			//this.updatePageTitle();
			app.dispatchEvent(new Event(Event.CHANGE));
		}
		
		private function eventDispatcher_documentNameChangedHandler(event:DocumentModelEvent):void
		{
			this.updatePageTitle();
		}
		
		private function eventDispatcher_newDocumentHandler(event:DocumentEvent):void
		{
			app.visible = true;
		}
		
		private function view_replaceTextureHandlerFromMoonshine(event:PropertyEditorEvent):void
		{
			if (app.isFileLoading) return;
			else app.isFileLoading = true;
			
			var tmpDRevent:DocumentRequestEvent = new DocumentRequestEvent(DocumentRequestEvent.REQUEST_OPEN_DOCUMENT);
			tmpDRevent.nextEvent2Moonshine = new ImportTextureEvent(ImportTextureEvent.IMPORT_AND_BITMAP_REPLACE_FROM_MOONSHINE, event.data as Array);
			this.dispatch(tmpDRevent);
		}
		
		private function event_saveRequestFromMoonshine(event:PropertyEditorEvent):void
		{
			this.dispatch(new SaveDocumentEvent(SaveDocumentEvent.SAVE_DOCUMENT));
		}
		
		private function context_itemSelectHandler(event:SceneEvent):void
		{
			if( event.items && event.items.length > 0)
			{
				var isSceneItemsSelected:Boolean = true;
				for each( var asset:AssetVO in event.items )
				{
					if( !(asset is ObjectVO) )
						isSceneItemsSelected = false;
				}
				
				getItemByValue( EMenuItem.FOCUS ).enabled = isSceneItemsSelected;
				getItemByValue( EMenuItem.DELETE ).enabled = true;
				getItemByValue( EMenuItem.COPY ).enabled = isSceneItemsSelected;
				getItemByValue( EMenuItem.CUT ).enabled = isSceneItemsSelected;
			}
			else 
			{
				getItemByValue( EMenuItem.FOCUS ).enabled = false;
				getItemByValue( EMenuItem.DELETE ).enabled = false;
				getItemByValue( EMenuItem.COPY ).enabled = false;
				getItemByValue( EMenuItem.CUT ).enabled = false;
			}
		}
		
		private function eventDispatcher_switchToFreeCameraHandler(event:SceneEvent):void
		{
			getItemByValue( EMenuItem.TARGET_CAMERA ).checked = false;
			getItemByValue( EMenuItem.FREE_CAMERA ).checked = true;
		}
		
		private function eventDispatcher_switchToTargetCameraHandler(event:SceneEvent):void
		{
			getItemByValue( EMenuItem.TARGET_CAMERA ).checked = false;
			getItemByValue( EMenuItem.FREE_CAMERA ).checked = true;
		}
		
		private function eventDispatcher_switchTranslateHandler(event:SceneEvent):void
		{
			getItemByValue( EMenuItem.TRANSLATE_MODE ).checked = true;
			getItemByValue( EMenuItem.ROTATE_MODE ).checked = false;
			getItemByValue( EMenuItem.SCALE_MODE ).checked = false;
		}
		
		private function eventDispatcher_switchRotateHandler(event:SceneEvent):void
		{
			getItemByValue( EMenuItem.TRANSLATE_MODE ).checked = false;
			getItemByValue( EMenuItem.ROTATE_MODE ).checked = true;
			getItemByValue( EMenuItem.SCALE_MODE ).checked = false;
		}
		
		private function eventDispatcher_switchScaleCameraHandler(event:SceneEvent):void
		{
			getItemByValue( EMenuItem.TRANSLATE_MODE ).checked = false;
			getItemByValue( EMenuItem.ROTATE_MODE ).checked = false;
			getItemByValue( EMenuItem.SCALE_MODE ).checked = true;
		}
		
		private function context_copyHandler(event:ClipboardEvent):void
		{
			getItemByValue( EMenuItem.PASTE ).enabled = true;
			getItemByValue( EMenuItem.CUT ).enabled = true;
		}
		
		private function awaybuilder_dragEnterHandler(event:DragEvent):void
		{
			const dragSource:DragSource = event.dragSource;
			if(dragSource.hasFormat("air:file list"))
			{
				var fileList:Array = dragSource.dataForFormat("air:file list") as Array;
				if(fileList.length == 1)
				{
					const extensions:Vector.<String> = new <String>["awd","3ds","obj","md2","png","jpg","atf","dae","md5"];
					for each(var file:File in fileList)
					{
						if(file.exists && extensions.indexOf(file.extension.toLowerCase()) >= 0)
						{
							DragManager.acceptDragDrop(this.app as UIComponent);
							break;
						}
					}
				}
			}
		}
		
		private function awaybuilder_dragDropHandler(event:DragEvent):void
		{
			var file:File = event.dragSource.dataForFormat("air:file list")[0];
			this.dispatch(new OpenFromInvokeEvent(OpenFromInvokeEvent.OPEN_FROM_INVOKE, file));
		}
		
		private function awaybuilder_closingHandler(event:Event):void
		{
			if(this.documentModel.edited)
			{
				if (event) event.preventDefault();
				this.dispatch(new DocumentRequestEvent(DocumentRequestEvent.REQUEST_CLOSE_DOCUMENT));
			}
		}
		
		private function menu_itemClickHandler(event:FlexNativeMenuEvent):void
		{	
			onItemSelect( event.item.value );
		}
		
		private function menuLib_itemClickHandler(event:MenuEvent):void
		{	
			onItemSelect( event.item.value );
		}
		
		private function onMenuLib_itemClickHandler(event:*):void
		{
			onItemSelect(event.data.label);
		}
		
		private function stage_keyDownHandler(event:KeyboardEvent):void
		{
			const focus:IFocusManagerComponent = app.focusManager.getFocus();
			if( focus is IIMESupport || ModalityManager.modalityManager.modalWindowCount > 0)
			{
				//if I can enter text into whatever has focus, then that takes
				//precedence over keyboard shortcuts.
				//if a modal window is open, or the menu is disabled, no
				//keyboard shortcuts are allowed
				return;
			}
			onKeyDown( event );
			
		}
		override protected function exit():void
		{
			//app.close();
		}
		
		private function dispose(event:Event):void
		{
			app.removeEventListener(AwayBuilderLibMain.DISPOSE, dispose);
			app.menu.removeEventListener(MenuEvent.ITEM_CLICK, menuLib_itemClickHandler);
			app.eventDispatcher.removeEventListener("awayBuilderMenuEvent", onMenuLib_itemClickHandler);
			
			removeContextListener( DocumentModelEvent.DOCUMENT_NAME_CHANGED, eventDispatcher_documentNameChangedHandler);
			removeContextListener( DocumentModelEvent.DOCUMENT_EDITED, eventDispatcher_documentEditedHandler);
			removeContextListener( SceneEvent.SELECT, context_itemSelectHandler);
			removeContextListener( SceneEvent.SWITCH_CAMERA_TO_FREE, eventDispatcher_switchToFreeCameraHandler);
			removeContextListener( SceneEvent.SWITCH_CAMERA_TO_TARGET, eventDispatcher_switchToTargetCameraHandler);
			removeContextListener( SceneEvent.SWITCH_TRANSFORM_TRANSLATE, eventDispatcher_switchTranslateHandler);
			removeContextListener( SceneEvent.SWITCH_TRANSFORM_ROTATE, eventDispatcher_switchRotateHandler);
			removeContextListener( SceneEvent.SWITCH_TRANSFORM_SCALE, eventDispatcher_switchScaleCameraHandler);
			removeContextListener( ClipboardEvent.CLIPBOARD_COPY, context_copyHandler);
			removeContextListener( UndoRedoEvent.UNDO_LIST_CHANGE, context_undoListChangeHandler);
			removeContextListener( ErrorLogEvent.LOG_ENTRY_MADE, eventDispatcher_errorLogHandler);
			
			removeViewListener( Event.CLOSING, awaybuilder_closingHandler );
			removeViewListener( DragEvent.DRAG_ENTER, awaybuilder_dragEnterHandler );
			removeViewListener( DragEvent.DRAG_DROP, awaybuilder_dragDropHandler );
			removeViewListener( InvokeEvent.INVOKE, invokeHandler );
			removeViewListener( PropertyEditorEvent.REPLACE_AND_LOAD_TEXTURE_FROM_MOONSHINE, view_replaceTextureHandlerFromMoonshine );
			removeViewListener( PropertyEditorEvent.SAVE_FROM_MOONSHINE, event_saveRequestFromMoonshine )
			
			this.eventMap.unmapListeners();
			
			app = null;
			
			documentModel = null;
			
			undoRedoModel = null;
		}
	}
}