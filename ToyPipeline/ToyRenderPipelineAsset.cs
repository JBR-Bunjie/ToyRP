using UnityEngine;
using UnityEngine.Rendering;

namespace ToyRP.ToyPipeline
{
    [CreateAssetMenu(menuName = "Rendering/ToyRenderPipeline")]
    public class ToyRenderPipelineAsset : RenderPipelineAsset
    {
        protected override RenderPipeline CreatePipeline()
        {
            return new ToyRenderPipeline();
            
        }
    }
}