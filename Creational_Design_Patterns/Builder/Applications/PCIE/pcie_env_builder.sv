typedef class pcie_env; 

class pcie_env_builder;

  function void build_phy(pcie_env env);
    env.phy_env = pcie_phy_env::type_id::create("phy_env", env);
  endfunction

  function void build_link(pcie_env env);
    env.link_env = pcie_link_env::type_id::create("link_env", env);
  endfunction

  function void build_tlp(pcie_env env);
    env.tlp_env = pcie_tlp_env::type_id::create("tlp_env", env);
  endfunction

  function void connect_layers(pcie_env env);
  /*   env.phy_env.phy_agent.ap.connect(
      env.link_env.link_agent.phy_export
    );

    env.link_env.link_agent.ap.connect(
      env.tlp_env.tlp_agent.link_export
    );
  */ 
  endfunction

endclass
