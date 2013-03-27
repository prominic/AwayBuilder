package awaybuilder.utils.scene
{
	import away3d.materials.ColorMaterial;
	import away3d.materials.MaterialBase;
	import away3d.materials.TextureMaterial;
	
	import awaybuilder.model.vo.MaterialVO;

	public class SceneUtils
	{
		public static function GetMaterialCopy( material:MaterialVO ):MaterialVO
		{
			var newMaterial:MaterialBase;
			if( material.linkedObject is TextureMaterial )
			{
				var textureMaterial:TextureMaterial =  material.linkedObject as TextureMaterial;
				newMaterial = new TextureMaterial( textureMaterial.texture, textureMaterial.smooth, textureMaterial.repeat, textureMaterial.mipmap );
				newMaterial.name = material.name + " (copy)";
			}
			if( material.linkedObject is ColorMaterial )
			{
				var colorMaterial:ColorMaterial = material.linkedObject as ColorMaterial;
				newMaterial = new ColorMaterial( colorMaterial.color, colorMaterial.alpha );
				newMaterial.name = material.name + " (copy)";
			}
			
			return new MaterialVO(newMaterial);
		}
	}
}