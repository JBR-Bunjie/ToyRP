using UnityEditor;
using UnityEngine;

namespace ToyRP.ToyPipeline.Editor.IBLPreCalculator
{
    public class IBLWindow : ToolWindow
    {
        public static Texture targetTexture;
        public static Texture diffuseR;
        public static Texture specularR;
        public static Texture Lut;
        private const string windowTitle = titlePrefix + "/IBL Pre-Calculator";
        
        [MenuItem(windowTitle)]
        protected static void ShowWindow() {
            var window = GetWindow<IBLWindow>();
            window.titleContent = new GUIContent("IBL Pre-Calc");
            window.Show();
        }

        private void OnGUI() {
            targetTexture = EditorGUILayout.ObjectField("targetTexture", targetTexture, typeof(Texture), true) as Texture;
        
            if (GUILayout.Button("Process")) {
                Diffuse.DiffuseCalc();
                Specular.SpecularCalc();
            }
        }
    }
}