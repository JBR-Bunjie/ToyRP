using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace ToyRP.ToyPipeline {
    public class ToyRenderPipeline : RenderPipeline
    {
        private RenderTexture gdepth;
        private RenderTexture[] gbuffers = new RenderTexture[4];
        private RenderTargetIdentifier[] gbufferID = new RenderTargetIdentifier[4];

        public ToyRenderPipeline()
        {
            gdepth = new RenderTexture(Screen.width, Screen.height, 24, RenderTextureFormat.Depth,
                RenderTextureReadWrite.Linear);
            gbuffers[0] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32,
                RenderTextureReadWrite.Linear);
            gbuffers[1] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB2101010,
                RenderTextureReadWrite.Linear);
            gbuffers[2] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB64,
                RenderTextureReadWrite.Linear);
            gbuffers[3] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGBFloat,
                RenderTextureReadWrite.Linear);

            for (int i = 0; i < 4; i++)
                gbufferID[i] = gbuffers[i];
        }

        void LightPass(ScriptableRenderContext context, Camera camera)
        {
            CommandBuffer cmd = new CommandBuffer();
            cmd.name = "lightPass";

            Material mat = new Material(Shader.Find("ToyRP/lightPass"));
            cmd.Blit(gbufferID[0], BuiltinRenderTextureType.CameraTarget, mat);
            context.ExecuteCommandBuffer(cmd);
        }
        
        protected override void Render(ScriptableRenderContext context, Camera[] cameras)
        {
            // 主相机
            Camera camera = cameras[0];
            context.SetupCameraProperties(camera);

            CommandBuffer cmd = new CommandBuffer();
            cmd.name = "gbuffer";

            // 清屏
            cmd.SetRenderTarget(gbufferID, gdepth);
            
            // set global textures
            cmd.SetGlobalTexture("_gdepth", gdepth);
            for(int i=0; i<4; i++) 
                cmd.SetGlobalTexture("_GT"+i, gbuffers[i]);
            // set global matrix
            Matrix4x4 viewMatrix = camera.worldToCameraMatrix;
            // Matrix4x4 projMatrix = camera.projectionMatrix;
            Matrix4x4 projMatrix = GL.GetGPUProjectionMatrix(camera.projectionMatrix, false);
            // Matrix4x4 vpMatrix = viewMatrix * projMatrix;
            Matrix4x4 vpMatrix = projMatrix * viewMatrix;
            Matrix4x4 vpMatrixInv = vpMatrix.inverse;
            cmd.SetGlobalMatrix("_vpMatrix", vpMatrix);
            cmd.SetGlobalMatrix("_vpMatrixInv", vpMatrixInv);
            
            cmd.ClearRenderTarget(true, true, Color.blue);
            context.ExecuteCommandBuffer(cmd);

            // 剔除
            camera.TryGetCullingParameters(out var cullingParameters);
            var cullingResults = context.Cull(ref cullingParameters);

            // config
            ShaderTagId shaderTagId = new("gbuffer");
            SortingSettings sortingSettings = new(camera);
            DrawingSettings drawingSettings = new(shaderTagId, sortingSettings);
            FilteringSettings filteringSettings = FilteringSettings.defaultValue;

            // Draw
            context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
            
            LightPass(context, camera);
            
            context.DrawSkybox(camera);
            if (Handles.ShouldRenderGizmos())
            {
                context.DrawGizmos(camera, GizmoSubset.PreImageEffects);
                context.DrawGizmos(camera, GizmoSubset.PostImageEffects);
            }
            
            
            // 最终提交绘制
            context.Submit();
        }
    }
}