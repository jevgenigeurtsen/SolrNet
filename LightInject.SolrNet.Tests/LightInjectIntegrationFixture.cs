// 

using System;
using HttpWebAdapters;
using Xunit;
using SolrNet;
using Xunit.Abstractions;

namespace LightInject.SolrNet.Tests
{
    
    [Trait("Category","Integration")]
    public class LightInjectIntegrationFixture 
    {
        private readonly ITestOutputHelper testOutputHelper;
        private readonly IServiceContainer defaultServiceProvider;
        private readonly IServiceContainer defaultServiceProviderAuth_WithAuth;
        private readonly IServiceContainer defaultServiceProviderAuth_WithoutAuth;

        public LightInjectIntegrationFixture(ITestOutputHelper testOutputHelper)
        {
            this.testOutputHelper = testOutputHelper;
            
            this.defaultServiceProvider = new ServiceContainer();
            this.defaultServiceProvider.AddSolrNet("http://localhost:8983/solr/techproducts");

            this.defaultServiceProviderAuth_WithAuth = new ServiceContainer();
            this.defaultServiceProviderAuth_WithAuth.AddSolrNet("http://localhost:8984/solr/techproducts",
                null,
                () => new BasicAuthHttpWebRequestFactory("solr", "SolrRocks"));


            this.defaultServiceProviderAuth_WithoutAuth = new ServiceContainer();
            this.defaultServiceProviderAuth_WithoutAuth.AddSolrNet("http://localhost:8984/solr/techproducts");
        }


        [Fact]
        public void Ping_And_Query()
        {
            var solr = defaultServiceProvider.GetInstance<ISolrOperations<LightInjectFixture.Entity>>();
            solr.Ping();
            testOutputHelper.WriteLine(solr.Query(SolrQuery.All).Count.ToString());
        }

        [Fact]
        public void Ping_And_Query_SingleCore()
        {
            var solr = defaultServiceProvider.GetInstance<ISolrOperations<LightInjectFixture.Entity>>();
            solr.Ping();
            testOutputHelper.WriteLine(solr.Query(SolrQuery.All).Count.ToString());
        }

        [Fact]
        public void Test_Auth_Solr_Setup()
        {
            var solr = defaultServiceProviderAuth_WithAuth.GetInstance<ISolrOperations<LightInjectFixture.Entity>>();
            solr.Ping();
            testOutputHelper.WriteLine(solr.Query(SolrQuery.All).Count.ToString());
        }

        [Fact]
        public void Test_Auth_Solr_Setup_Fails()
        {
            var solr = defaultServiceProviderAuth_WithoutAuth.GetInstance<ISolrOperations<LightInjectFixture.Entity>>();
            solr.Ping();
            testOutputHelper.WriteLine(solr.Query(SolrQuery.All).Count.ToString());
        }
    }
}
